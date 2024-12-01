// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "mahdi",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)  // Required minimum version for dependencies
    ],
    products: [
        .library(
            name: "mahdi",
            type: .dynamic,
            targets: ["mahdi"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.2.0"),
        .package(url: "https://github.com/google/GoogleSignIn-iOS.git", from: "7.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-perception", from: "1.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-case-paths", from: "1.0.0"),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.0"),
        .package(url: "https://github.com/ReSwift/ReSwift.git", from: "6.1.0"),
    ],
    targets: [
        .target(
            name: "mahdi",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),
                .product(name: "GoogleSignInSwift", package: "GoogleSignIn-iOS"),
                .product(name: "Perception", package: "swift-perception"),
                .product(name: "CasePaths", package: "swift-case-paths"),
                .product(name: "SwiftyJSON", package: "SwiftyJSON"),
                .product(name: "ReSwift", package: "ReSwift"),
            ],
            path: "Sources/mahdi",
            exclude: ["Resources/Info.plist"],
            resources: [
                .process("Assets"),
                .process("Resources/Loudness.plist"),
                .process("Resources/Strings")
            ]
        ),
        .testTarget(
            name: "mahdiTests",
            dependencies: ["mahdi"],
            path: "Tests/mahdiTests"
        ),
    ]
)
