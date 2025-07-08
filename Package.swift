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
            name: "JustAMap",
            targets: ["JustAMap"]
        )
    ],
    dependencies: [],
    targets: [
        // Main target with all app code
        .target(
            name: "JustAMap",
            dependencies: [],
            path: "Sources/JustAMap",
            resources: [
                .process("Resources")
            ]
        ),
        // Test target
        .testTarget(
            name: "JustAMapTests",
            dependencies: ["JustAMap"],
            path: "Tests/JustAMapTests"
        )
    ]
)