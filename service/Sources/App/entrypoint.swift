import Vapor
import Logging
import NIOCore
import NIOPosix
import NIOConcurrencyHelpers
import Whooshing
import ErrorHandle

@main
enum Entrypoint {
    enum Err: String, ErrList {
        var domain: String { "woo.sys.configurate.error" }
        case illegalService = "不合法的服务模块"
    }
    
    static func main() async throws {
        var services: [Application.ServiceType] = []
        #if API
        services.append(.api)
        #endif
        #if INLINE
        services.append(.inline)
        #endif
        #if HTTPS
        services.append(.https)
        #endif
        for service in services {
            var env = try Environment.detect()
            try LoggingSystem.bootstrap(from: &env)
            let app = try await Application.make(env)
            switch service {
                #if INLINE
                case .inline: Woo.https = app
                #endif
                #if HTTPS
                case .https: Woo.inline = app
                #endif
                #if API
                case .api: Woo.api = app
                #endif
                #if !(INLINE && HTTPS && API)
                default: fatalError(Err.illegalService.d(service.rawValue, 20100, (#file, #line)).description)
                #endif
            }
            do {
                try await app.configure(for: .https)
                switch service {
                    #if INLINE
                    case .inline: try await Configuration.inline(app)
                    #endif
                    #if HTTPS
                    case .https: try await Configuration.https(app)
                    #endif
                    #if API
                    case .api: try await Configuration.api(app)
                    #endif
                    #if !(INLINE && HTTPS && API)
                    default: fatalError(Err.illegalService.d(service.rawValue, 20101, (#file, #line)).description)
                    #endif
                }
            } catch {
                app.logger.report(error: error)
                try? await app.asyncShutdown()
                throw error
            }
            try await app.execute()
            try await app.asyncShutdown()
        }
    }
}

@MainActor
struct Woo {
    #if HTTPS
    fileprivate(set) static var https: Application!
    #endif
    #if INLINE
    fileprivate(set) static var inline: Application!
    #endif
    #if API
    fileprivate(set) static var api: Application!
    #endif
}
