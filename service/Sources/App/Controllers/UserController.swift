import Vapor
import Fluent
import WhooshingServer
import DataConvertable
import ErrorHandle
import Cryptos

/// 用户认证模块，实现
/// - 用户注册
/// - 用户登陆
/// - 用户口令认证

struct UserController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let userRoute = routes.grouped("user")
        userRoute.post("register", use: register)
        userRoute.post("auth", use: authenticate)
        let basicProtected = userRoute.grouped(User.authenticator())
        basicProtected.post("login", use: login)
    }
    
    // 用户注册，若成功，返回 Registered 字符串
    @Sendable func register(req: Request) async throws -> String {
        // 验证注册者的请求是否合格，email + hashed password
        try NewUser.validate(content: req)
        let newUser = try req.content.decode(NewUser.self)
        let user = try newUser.user()
        try await user.save(on: req.db)
        return "Registered"
    }
    
    // 用户登陆，若成功，返回用户凭据和登陆口令
    @Sendable func login(req: Request) async throws -> TokenDTO {
        let user = try req.auth.require(User.self)
        let token = try Token(for: user.requireID())
        // 删除原有的 token (若有)
        try await Token.query(on: req.db).filter(\.$user.$id == user.requireID()).delete()
        try await token.save(on: req.db)
        return token.DTO
    }
    
    // 验证口令，若成功，返回用户口令
    @Sendable func authenticate(req: Request) async throws -> Crypto.Symm.Key {
        let tokenAuth = try req.content.decode(TokenAuth.self)
        guard tokenAuth.tokenEncrypted.count == 60 else { throw Abort(.badRequest, reason: "用户口令长度不正确") }
        // 从数据库中查询用户凭据
        guard let token = try await Token.query(on: req.db).filter(\.$credential == tokenAuth.credential).first() else { throw Abort(.badRequest, reason: "用户凭据不存在") }
        try await token.$user.load(on: req.db)
        // 检查是否有效
        guard token.valid == true else { throw Abort(.badRequest, reason: "用户口令无效")  }
        // 检查是否已过期
        let expireDate = token.createdAt.addingTimeInterval(TimeInterval(token.expireAfter * 60))
        guard Date.now < expireDate else { throw Abort(.badRequest, reason: "用户凭据已过期") }
        // 检查口令是否正确
        let keyData = try Base64String(token.token).data()                                                          // 取得密钥的字节码
        let key = Crypto.Symm.Key(data: keyData)                                                                    // 转为 AES 密钥类型
        let authData: Data = try Crypto.Symm.decrypt(tokenAuth.tokenEncrypted, key: key)                            // 解密 tokenEncrypted
        guard keyData == authData else { throw Abort(.badRequest, reason: "用户口令不正确") }                          // key 是否一致
        return key
    }
}