import Vapor
import Fluent
import WhooshingInline
import ErrorHandle
import Cryptos

/// 用户认证模块，实现
/// - 用户注册
/// - 用户登陆
/// - 用户口令认证

struct UserController: RouteCollection {
    enum Err: String, ErrList {
        var domain: String { "woo.sys.authentication.service.user.controller.error" }
        case registerFailed = "注册失败"
        case loginFailed = "登陆失败"
        case authFailed = "验证失败"
    }
    
    func boot(routes: any RoutesBuilder) throws {
        let userRoute = routes.grouped("user")
        userRoute.post("register", use: register)
        userRoute.post("login", use: login)
        userRoute.post("auth", use: authenticate)
    }
    
    // 用户注册，若成功，返回 Registered 字符串
    @Sendable func register(req: Request) async throws -> String {
        do {
            // 验证注册者的请求是否合格，email + hashed password
            try NewUser.validate(query: req)
            let newUser = try req.content.decode(NewUser.self)
            let user = try newUser.user()
            try await user.save(on: req.db)
            return "Registered"
        } catch let err {
            throw Err.registerFailed.d(20002, (#file, #line)).subErr(err)
        }
    }
    
    // 用户登陆，若成功，返回用户凭据和登陆口令
    @Sendable func login(req: Request) async throws -> TokenDTO {
        do {
            let user = try req.auth.require(User.self)
            let token = try Token(for: user.requireID())
            // 删除原有的 token (若有)
            try await Token.query(on: req.db).filter(\.$user.$id == user.requireID()).delete()
            try await token.save(on: req.db)
            return token.DTO
        } catch let err {
            throw Err.loginFailed.d(20003, (#file, #line)).subErr(err)
        }
    }
    
    // 验证口令，若成功，返回 Pass
    @Sendable func authenticate(req: Request) async throws -> String {
        enum AuthErr: String, Error {
            case credentialNotExist = "用户凭据不存在"
            case credentialExpired = "用户凭据已过期"
            case tokenIncorrect = "用户口令不正确"
            case tokenInvalid = "用户口令无效"
        }
        do {
            let tokenDTO = try req.content.decode(TokenDTO.self)
            // 从数据库中查询用户凭据
            guard let token = try await Token.query(on: req.db).filter(\.$credential == tokenDTO.credential).first() else { throw AuthErr.credentialNotExist }
            try await token.$user.load(on: req.db)
            // 检查是否有效
            guard token.valid == true else { throw AuthErr.tokenInvalid }
            // 检查是否已过期
            let expireDate = token.createdAt.addingTimeInterval(TimeInterval(token.expireAfter * 60))
            guard Date.now < expireDate else { throw AuthErr.credentialExpired }
            // 检查口令是否正确
            guard token.token == tokenDTO.token else { throw AuthErr.tokenIncorrect }
            return "Pass"
        } catch let err {
            throw Err.authFailed.d(20004, (#file, #line)).subErr(err)
        }
    }
}
