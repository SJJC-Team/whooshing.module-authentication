// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "service",
    platforms: [
       .macOS(.v13)
    ],
    dependencies: [
        .package(path: "/root/projects/whooshing-vapor"),
        .package(path: "~/projects/whooshing.toolbox-basic"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "whooshing-vapor"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "Whooshing", package: "whooshing.toolbox-basic"),
            ],
            swiftSettings: swiftSettings + ["HTTPS"].map { .define($0) }
        ),
        .testTarget(
            name: "AppTests",
            dependencies: [
                .target(name: "App"),
                .product(name: "VaporTesting", package: "whooshing-vapor"),
            ],
            swiftSettings: swiftSettings
        )
    ],
    swiftLanguageModes: [.v5]
)

var swiftSettings: [SwiftSetting] { [
    .enableUpcomingFeature("DisableOutwardActorInference"),
    .enableExperimentalFeature("StrictConcurrency"),
] }
