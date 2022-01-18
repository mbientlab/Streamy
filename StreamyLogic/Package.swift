// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "StreamyLogic",
    platforms: [.macOS(.v12), .iOS(.v15), .watchOS(.v8), .tvOS(.v15)],
    products: [
        .library(name: "StreamyLogic", targets: ["StreamyLogic"]),
    ],
    dependencies: [
        .package(
            name: "MetaWear",
            url: "https://github.com/mbientlab/MetaWear-Swift-Combine-SDK",
            branch: "main"
        )
    ],
    targets: [
        .target(name: "StreamyLogic", dependencies: [
            .product(name: "MetaWear", package: "MetaWear", condition: nil),
            .product(name: "MetaWearSync", package: "MetaWear", condition: nil)
        ]),
        .testTarget(name: "StreamyLogicTests", dependencies: ["StreamyLogic"]),
    ]
)
