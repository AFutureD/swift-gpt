// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-gpt",
    platforms: [.macOS(.v14), .iOS(.v16)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "GPT",
            targets: ["GPT"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),

        .package(url: "https://github.com/Myoland/swift-lazy", from: "0.2.1"),
        .package(url: "https://github.com/objecthub/swift-dynamicjson", from: "1.0.2"),
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.8.2"),
        .package(url: "https://github.com/apple/swift-algorithms", from: "1.2.1"),
        .package(url: "https://github.com/AFutureD/swift-synchronization", from: "0.1.0"),
        .package(url: "https://github.com/apple/swift-log", from: "1.6.0"),
        .package(url: "https://github.com/apple/swift-distributed-tracing", from: "1.3.1"),

        // Test
        .package(url: "https://github.com/swift-server/swift-openapi-async-http-client", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "GPT",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "SynchronizationKit", package: "swift-synchronization"),
                .product(name: "LazyKit", package: "swift-lazy"),
                .product(name: "TraceKit", package: "swift-lazy"),
                .product(name: "NetworkKit", package: "swift-lazy"),
                .product(name: "DynamicJSON", package: "swift-dynamicjson"),
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "Algorithms", package: "swift-algorithms"),
                .product(name: "Tracing", package: "swift-distributed-tracing"),
            ]
        ),
        .testTarget(
            name: "GPTTests",
            dependencies: [
                "GPT",
                .product(name: "TestKit", package: "swift-lazy"),
                .product(name: "OpenAPIAsyncHTTPClient", package: "swift-openapi-async-http-client"),
            ]
        ),
    ]
)
