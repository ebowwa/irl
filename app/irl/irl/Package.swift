// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "irl",
    products: [
        .executable(name: "irl", targets: ["irl"]),
    ],
    dependencies: [
        // Add your package dependencies here
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.15.3"),
        .package(url: "https://github.com/fal-ai/fal-swift.git", from: "0.1.0"),
        .package(url: "https://github.com/warrenm/GLTFKit2.git", from: "0.5.11"),
        .package(url: "https://github.com/apple/swift-numerics.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "irl",
            dependencies: [
                "SQLite",
                "fal-swift",
                "GLTFKit2",
                "Numerics",
            ]),
    ]
)
