// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Injectable",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Injectable",
            targets: ["Injectable"]
        ),
        .plugin(
            name: "InjectablePlugin",
            targets: ["InjectablePlugin"]
        ),
    ],
    dependencies: [],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Injectable",
            dependencies: []
        ),
        .testTarget(
            name: "InjectableTests",
            dependencies: ["Injectable"],
            plugins: [.plugin(name: "InjectablePlugin")]
        ),
        .binaryTarget(name: "InjectableTool",
                      url: "https://github.com/valentinradu/InjectableTool/releases/download/v1.0.3/InjectableTool.artifactbundle.zip",
                      checksum: "bdda55958f8324a174a09516215455c7813a63c7687409055639f57589bd3649"),
        .plugin(name: "InjectablePlugin",
                capability: .buildTool(),
                dependencies: ["InjectableTool"]),
    ]
)
