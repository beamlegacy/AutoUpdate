// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "AppFeedBuilder",
    platforms: [
        .macOS(.v10_15)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMajor(from: "1.0.0"))
    ],
    targets: [
        .target(name: "AppFeedBuilder",
                dependencies: [.product(name: "ArgumentParser", package: "swift-argument-parser")])
    ]
)
