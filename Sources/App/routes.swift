import Vapor
import WhooshingServer

func routes<T>(_ woo: Whooshing<T>, _ app: Application) throws where T: ServiceType {
    try app.register(collection: UserController())
}
