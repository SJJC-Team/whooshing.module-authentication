import Vapor
import WhooshingServer

struct Configuration {
    /// 对 Https 模块进行配置，如果设置了 HTTPS 环境变量
    /// 取决于 Package.swift 的 swiftSettings 中的环境变量设置
    static func https(_ woo: Whooshing<Https>, app: Application) async throws {
        app.migrations.add(User.MIG())
        app.migrations.add(Token.MIG())
        try await app.autoMigrate()
        try routes(app)
    }
    
    /// 对 Inline 模块进行配置
    /// Inline 模块为每个服务模块的必须，因此不支持在 swiftSettings 中设置
    static func inline(_ woo: Whooshing<Inline>, app: Application) async throws {
        app.migrations.add(User.MIG())
        app.migrations.add(Token.MIG())
        try await app.autoMigrate()
        try routes(app)
    }
}
