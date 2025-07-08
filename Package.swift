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
            name: "JustAMapKit",
            targets: ["JustAMapKit"]
        ),
        .executable(
            name: "JustAMapApp",
            targets: ["JustAMapApp"]
        )
    ],
    dependencies: [],
    targets: [
        // Library target containing the core functionality
        .target(
            name: "JustAMapKit",
            dependencies: [],
            path: "Sources/JustAMapKit",
            resources: [
                .process("Resources")
            ]
        ),
        // Executable target for the iOS app
        .executableTarget(
            name: "JustAMapApp",
            dependencies: ["JustAMapKit"],
            path: "Sources/JustAMapApp"
        ),
        // Test target
        .testTarget(
            name: "JustAMapKitTests",
            dependencies: ["JustAMapKit"],
            path: "Tests/JustAMapKitTests"
        )
    ]
)