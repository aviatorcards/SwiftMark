// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SwiftMark",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
    ],
    products: [
        .library(
            name: "SwiftMark",
            targets: ["SwiftMark"]
        ),
        .executable(
            name: "swiftmark-cli",
            targets: ["SwiftMarkCLI"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-markdown.git", from: "0.5.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0"),
        .package(url: "https://github.com/JohnSundell/Splash.git", from: "0.16.0"),
        .package(url: "https://github.com/apple/swift-testing.git", from: "0.12.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
    ],
    targets: [
        .target(
            name: "SwiftMark",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown"),
                .product(name: "Yams", package: "Yams"),
                .product(name: "Splash", package: "Splash"),
            ]
        ),
        .executableTarget(
            name: "SwiftMarkCLI",
            dependencies: [
                "SwiftMark",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "SwiftMarkTests",
            dependencies: [
                "SwiftMark",
                .product(name: "Testing", package: "swift-testing"),
            ]
        )
    ]
)
