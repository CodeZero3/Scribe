// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Scribe",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/argmaxinc/WhisperKit", .upToNextMajor(from: "0.9.0")),
        .package(url: "https://github.com/soffes/HotKey", .upToNextMajor(from: "0.2.0")),
    ],
    targets: [
        .executableTarget(
            name: "Scribe",
            dependencies: [
                "WhisperKit",
                "HotKey",
            ],
            path: "Sources/Scribe"
        ),
    ]
)
