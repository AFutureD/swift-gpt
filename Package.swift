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
            targets: ["GPT"]),
    ],
    dependencies: [
        .package(url: "https://github.com/objecthub/swift-dynamicjson", from: "1.0.2"),
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.8.2"),
        .package(path: "../swift-lazy"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "GPT",
            dependencies: [
                .product(name: "LazyKit", package: "swift-lazy"),
                .product(name: "NetworkKit", package: "swift-lazy"),
                .product(name: "DynamicJSON", package: "swift-dynamicjson"),
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
            ]
        ),
        .testTarget(
            name: "GPTTests",
            dependencies: ["GPT"]
        ),
    ]
)
