import PgSQL
import Fluent
import Foundation
import Vapor
import DataConvertable
import Cryptos
import ErrorHandle

final class Token: PGModel, @unchecked Sendable {
    static let name: String = "tokens"
    
    struct Fields: PGFields {
        let id = PGField("id", .uuid)                               .cons([.required])
        let user = PGField("user_id", User.fields.id.dataType)      .cons([.required, .references(User.schema, User.fields.id.key)])
        let credential = PGField("credential", .string, true)       .cons([.required])
        let token = PGField("token", .string, true)                 .cons([.required])
        let valid = PGField("valid", .bool).def(true)               .cons([.required])  // 是否有效
        let expireAfter = PGField("expire_after", .uint32)          .cons([.required])  // 过期时间，单位为分
        let createdAt = PGField("create_at", .string)               .cons([.required])
    }
    
    static let fields: Fields = Fields()
    
    @ID(key: .id)                                                   var id: UUID?
    @Parent(fields.user)                                            var user: User
    @Field(fields.credential)                                       var credential: String
    @Field(fields.token)                                            var token: String
    @Field(fields.valid)                                            var valid: Bool
    @Field(fields.expireAfter)                                      var expireAfter: UInt32
    @Timestamp(fields.createdAt, on: .create)                       var createdAt: Date!
    
    init() {}
    
    init(for userId: User.IDValue) throws {
        self.$user.id = userId
        self.credential = try Crypto.randomDataGenerate(length: 16).base64EncodedString()
        self.token = try Crypto.randomDataGenerate(length: 128).base64EncodedString()
        self.expireAfter = 7 * 24 * 60      // 7 天，以分钟为单位
    }
    
    struct MIG: PGMigration, Sendable { typealias DataModel = Token }
}

extension Token: ModelCredentialsAuthenticatable {
    static let usernameKey = \Token.$credential
    static let passwordHashKey = \Token.$token
    func verify(password: String) throws -> Bool { password == self.token }
}
