// swift-tools-version: 6.0
import PackageDescription
let package = Package(
    name: "JustAMap-Builder",
    platforms: [
        .iOS("17.0"),
    ],
    dependencies: [
        .package(name: "RootPackage", path: "../.."),
    ],
    targets: [
        .executableTarget(
            name: "JustAMap-App",
            dependencies: [
                .product(name: "JustAMap", package: "RootPackage"),
            ]
        ),
    ]
)
