import Vapor
import Logging
import NIOCore
import NIOPosix
import Whooshing
import ErrorHandle

/// 该函数为入口函数，是整个 Vapor 服务的执行起始点
/// 该函数根据环境变量(API, INLINE, HTTPS)分别设置服务类型，并进行初始化
/// 环境变量可在 Package.swift 中设置
/// 不同服务的 Application 实例可以分别通过 Woo.api, Woo.inline, Woo.https 来取得
/// 要对不同的实例进行额外配置，在 configure.swift 进行额外配置

@main
enum Entrypoint {
    enum Err: String, ErrList {
        var domain: String { "woo.sys.template.configurate.error" }
        case illegalService = "不合法的服务模块"
    }
    
    static func main() async throws {
        var services: [Application.ServiceType] = []
        #if API
        services.append(.api)
        #endif
        #if HTTPS
        services.append(.https)
        #endif
        #if INLINE
        services.append(.inline)
        #endif
        for service in services {
            var env = try Environment.detect()
            try LoggingSystem.bootstrap(from: &env)
            let app = try await Application.make(env)
            switch service {
                #if API
                case .api: Woo.api = app
                #endif
                #if HTTPS
                case .https: Woo.inline = app
                #endif
                #if INLINE
                case .inline: Woo.https = app
                #endif
                #if !(INLINE && HTTPS && API)
                default: fatalError(Err.illegalService.d(service.rawValue, 20100, (#file, #line)).description)
                #endif
            }
            do {
                try await app.configure(for: .https)
                switch service {
                    #if API
                    case .api: try await Configuration.api(app)
                    #endif
                    #if HTTPS
                    case .https: try await Configuration.https(app)
                    #endif
                    #if INLINE
                    case .inline: try await Configuration.inline(app)
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
    #if API
    fileprivate(set) static var api: Application!
    #endif
    #if HTTPS
    fileprivate(set) static var https: Application!
    #endif
    #if INLINE
    fileprivate(set) static var inline: Application!
    #endif
}
