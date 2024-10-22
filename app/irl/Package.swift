// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "IRL",
    platforms: [
        .iOS(.v15) // Adjust this based on your deployment target
    ],
    products: [
        .library(
            name: "IRL",
            targets: ["IRL"]
        ),
    ],
    dependencies: [
        // Adding SQLite.swift
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.15.3"),
        // Adding swift-numerics for ComplexModule, Numerics, and RealModule
        .package(url: "https://github.com/apple/swift-numerics", from: "1.0.2")
    ],
    targets: [
        .target(
            name: "IRL",
            dependencies: [
                .product(name: "SQLite", package: "SQLite.swift"),
                .product(name: "ComplexModule", package: "swift-numerics"),
                .product(name: "Numerics", package: "swift-numerics"),
                .product(name: "RealModule", package: "swift-numerics")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "IRLTests",
            dependencies: ["IRL"]
        )
    ]
)
