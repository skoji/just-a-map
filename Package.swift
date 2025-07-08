// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "JustAMap",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "JustAMapCore",
            targets: ["JustAMapCore"]
        ),
        .executable(
            name: "JustAMapApp",
            targets: ["JustAMapApp"]
        )
    ],
    dependencies: [],
    targets: [
        // Core library without @main
        .target(
            name: "JustAMapCore",
            dependencies: [],
            path: "Sources/JustAMapCore",
            resources: [
                .process("Resources")
            ]
        ),
        // App executable with @main
        .executableTarget(
            name: "JustAMapApp",
            dependencies: ["JustAMapCore"],
            path: "Sources/JustAMapApp"
        ),
        // Test target
        .testTarget(
            name: "JustAMapTests",
            dependencies: ["JustAMapCore"],
            path: "Tests/JustAMapTests"
        )
    ]
)