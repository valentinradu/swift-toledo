// swift-tools-version: 5.6
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
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Toledo"
        ),
        .testTarget(
            name: "ToledoTests",
            dependencies: ["Toledo"],
            plugins: [.plugin(name: "ToledoPlugin")]
        ),
        .binaryTarget(name: "ToledoTool", path: "./Binaries/ToledoTool.artifactbundle.zip"),
        .plugin(
            name: "ToledoPlugin",
            capability: .buildTool(),
            dependencies: [
                .target(name: "ToledoTool"),
            ]
        ),
    ]
)
