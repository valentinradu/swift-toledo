// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Toledo",
    platforms: [
        .iOS(.v14), .macOS(.v11), .tvOS(.v14),
        .macCatalyst(.v14), .watchOS(.v7), .driverKit(.v20),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Toledo",
            targets: ["Toledo"]
        ),
        .plugin(
            name: "ToledoPlugin",
            targets: ["ToledoPlugin"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-syntax.git",
            .upToNextMajor(from: "508.0.0")
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Toledo"
        ),
        .executableTarget(
            name: "ToledoTool",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxParser", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
            ]
        ),
        .testTarget(
            name: "ToledoTests",
            dependencies: ["Toledo"],
            plugins: [.plugin(name: "ToledoPlugin")]
        ),
        .plugin(
            name: "ToledoPlugin",
            capability: .buildTool(),
            dependencies: [
                .target(name: "ToledoTool"),
            ]
        ),
    ]
)
