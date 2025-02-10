import Vapor
import WhooshingInline

public func configure(_ app: Application) async throws {
    try await Application.configure(app)
    app.migrations.add(User.MIG())
    try await app.autoMigrate()
    try routes(app)
}
