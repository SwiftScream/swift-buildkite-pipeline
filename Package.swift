// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-buildkite-pipeline",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "BuildkitePipeline",
            targets: ["BuildkitePipeline"],
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.1.3"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "BuildkitePipeline",
            dependencies: [
                .product(name: "Yams", package: "Yams"),
            ],
            resources: [.process("PrivacyInfo.xcprivacy")],
        ),
        .testTarget(
            name: "BuildkitePipelineTests",
            dependencies: ["BuildkitePipeline"],
            resources: [
                .copy("Fixtures"),
            ],
        ),
    ],
)
