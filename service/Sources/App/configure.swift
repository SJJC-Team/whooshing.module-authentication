import Vapor
import Whooshing

struct Configuration {
    static func inline(_ app: Application) async throws {
        app.migrations.add(User.MIG())
        try await app.autoMigrate()
        try routes(app)
    }
    
    static func api(_ app: Application) async throws { }
    
    static func https(_ app: Application) async throws { }
}
