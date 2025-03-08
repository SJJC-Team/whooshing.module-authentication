import Vapor
import ErrorHandle
import Cryptos
import DataConvertable

struct NewUser: Content, Validatable {
    let email: String
    let passwordHashed: String
    
    func user() throws -> User {
        let user = User()
        user.email = self.email
        // 为用户创建一个用户加密密钥
        user.key = Crypto.Symm.makeKey().data()
        user.salt = Crypto.randomDataGenerate()
        // 对用户密码进行第二重加盐哈希
        let passwd = try Crypto.hash(Base64String(self.passwordHashed).data() + user.salt)
        user.hashedPasswd = passwd.base64EncodedString()
        return user
    }
    
    static func validations(_ validations: inout Vapor.Validations) {
        validations.add("email", as: String.self, is: .email)
        validations.add("passwordHashed", as: String.self, is: .count(8...))
    }
}

struct TokenDTO: Content {
    let credential: String
    let token: String
}

extension Token {
    var DTO: TokenDTO { .init(credential: self.credential, token: self.token) }
}

struct TokenAuth: Content {
    let credential: String
    let tokenHashed: Data
}
