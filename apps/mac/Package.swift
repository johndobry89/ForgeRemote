// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "ForgeRemote",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "ForgeRemote", targets: ["ForgeRemote"])],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", exact: "4.110.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.77.0"),
        .package(url: "https://github.com/vapor/websocket-kit.git", exact: "2.16.2")
    ],
    targets: [
        .executableTarget(name: "ForgeRemote", dependencies: [
            .product(name: "Vapor", package: "vapor"),
            .product(name: "NIOHTTP1", package: "swift-nio"),
            .product(name: "NIOWebSocket", package: "swift-nio"),
            .product(name: "WebSocketKit", package: "websocket-kit")
        ]),
        .testTarget(name: "ForgeRemoteTests", dependencies: [
            "ForgeRemote", .product(name: "XCTVapor", package: "vapor")
        ])
    ]
)
