// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "AutoUpdate",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
      .library(name: "AutoUpdate", targets: ["AutoUpdate"]),
      .library(name: "Common", targets: ["Common"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMajor(from: "1.0.0"))
    ],
    targets: [
        .target(name: "AppFeedBuilder",
                dependencies: [.product(name: "ArgumentParser", package: "swift-argument-parser"),
                               .target(name: "Common")],
                path: "AppFeedBuilder"),
        .target(name: "AutoUpdate",
                dependencies: [.target(name: "Common")],
                path: "AutoUpdate"),
        .target(name: "Common",
                path: "Common")
    ]
)
