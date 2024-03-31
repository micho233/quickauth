// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "QuickAuth",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .watchOS(.v7),
        .tvOS(.v13)
    ],
    products: [
        .library(
            name: "QuickAuth",
            targets: ["QuickAuth",
                      "QuickAuthMonitor"]),
    ],
    targets: [
        .target(
            name: "QuickAuth"),
        .target(
            name: "QuickAuthMonitor"),
        .testTarget(
            name: "QuickAuthTests",
            dependencies: ["QuickAuth"]),
    ]
)
