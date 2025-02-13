import Vapor
import Whooshing

struct Configuration {
    /// 对 Inline 模块进行配置，如果设置了 INLINE 环境变量
    static func inline(_ app: Application) async throws {
        app.migrations.add(User.MIG())
        try await app.autoMigrate()
        try routes(app)
    }
    
    /// 对 Api 模块进行配置，如果设置了 API 环境变量
    static func api(_ app: Application) async throws {
        app.migrations.add(User.MIG())
        try await app.autoMigrate()
        try routes(app)
    }
    
    /// 对 Https 模块进行配置，如果设置了 HTTPS 环境变量
    static func https(_ app: Application) async throws {
        app.migrations.add(User.MIG())
        try await app.autoMigrate()
        try routes(app)
    }
}
