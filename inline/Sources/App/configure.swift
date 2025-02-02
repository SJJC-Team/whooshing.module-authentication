import Vapor
import Whooshing

// configures your application
public func configure(_ app: Application) async throws {
    try await Application.configure(app, template: .inline)
    try routes(app)
}
