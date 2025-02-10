import PgSQL
import Fluent
import Foundation
import Vapor
import DataConvertable
import Cryptos
import ErrorHandle

final class User: PGModel, @unchecked Sendable {
    static let name: String = "users"
    
    struct Fields: PGFields {
        let id = PGField("id", .uuid)                               .cons([.required])
        let email = PGField("email", .string, true)                 .cons([.required])
        let hashedPasswd = PGField("hashed_passwd", .string)        .cons([.required])
        let key = PGField("key", .data)                             .cons([.required])
        let salt = PGField("salt", .data)                           .cons([.required])
        let createdAt = PGField("create_at", .string)               .cons([.required])
        let updateAt = PGField("update_at", .string)                .cons([.required])
    }
    
    static let fields = Fields()
    
    @ID(key: .id)                                                   var id: UUID?
    @Field(fields.email)                                            var email: String
    @Field(fields.hashedPasswd)                                     var hashedPasswd: String
    @Field(fields.key)                                              var key: Data
    @Field(fields.salt)                                             var salt: Data
    @Timestamp(fields.createdAt, on: .create)                       var createdAt: Date!
    @Timestamp(fields.updateAt, on: .update)                        var updateAt: Date!
    
    init() {}
    
    struct MIG: PGMigration, Sendable { typealias DataModel = User }
}

extension User: ModelAuthenticatable {
    static let usernameKey = \User.$email
    static let passwordHashKey = \User.$hashedPasswd

    func verify(password: String) throws -> Bool {
        // 客户端请求所提供的密码是 其对其用户明文密码进行单次哈希的结果
        let passwd = try Base64String(password).data()
        // 对客户端密码设置后置盐，并再次哈希
        let hashed = Crypto.hash(passwd + self.salt)
        return try hashed == Base64String(self.hashedPasswd).data()
    }
}
