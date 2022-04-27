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
                      checksum: "1488221f750549a2bf16b2e6212159663bbb9ecc655c75c6bfdbf5c551eb7884"),
        .plugin(name: "InjectablePlugin",
                capability: .buildTool(),
                dependencies: ["InjectableTool"]),
    ]
)
