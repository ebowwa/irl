// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "caringmind",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "caringmind",
            targets: ["caringmind"]),
    ],
    dependencies: [
        .package(url: "https://github.com/google/GoogleSignIn-iOS.git", from: "7.1.0"),
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.16.1"),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.2"),
        .package(url: "https://github.com/ReSwift/ReSwift.git", from: "6.1.1"),
        .package(url: "https://github.com/realm/SwiftLint", from: "0.54.0")
    ],
    targets: [
        .target(
            name: "caringmind",
            dependencies: [
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                "SwiftyJSON",
                "ReSwift"
            ],
            exclude: ["Resources/Info.plist"],
            resources: [
                .copy("Resources")
            ]
        ),
        .testTarget(
            name: "caringmindTests",
            dependencies: ["caringmind"]
        ),
    ]
)
