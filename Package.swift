// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "JustAMap",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "JustAMap",
            targets: ["JustAMap"]),
    ],
    targets: [
        .target(
            name: "JustAMap",
            path: "JustAMap"),
        .testTarget(
            name: "JustAMapTests",
            dependencies: ["JustAMap"],
            path: "JustAMap/Tests"),
    ]
)