import ProjectDescription
import Foundation

// Load environment variables
let env = ProcessInfo.processInfo.environment

// Environment variable getters with defaults
func getEnvVar(_ key: String, default: String = "") -> String {
    return env[key] ?? `default`
}

let bundleIdPrefix = getEnvVar("BUNDLE_ID_PREFIX", default: "com.caringmind")
let developmentTeamId = getEnvVar("DEVELOPMENT_TEAM_ID", default: "")
let marketingVersion = getEnvVar("MARKETING_VERSION", default: "1.0.0")
let currentProjectVersion = getEnvVar("CURRENT_PROJECT_VERSION", default: "1")

let destinations: Destinations = [.iPhone, .iPad]

let project = Project(
    name: "CaringMind",
    options: .options(
        automaticSchemesOptions: .disabled,
        disableBundleAccessors: false,
        disableShowEnvironmentVarsInScriptPhases: false,
        disableSynthesizedResourceAccessors: false,
        textSettings: .textSettings(),
        xcodeProjectName: nil
    ),
    packages: [
        .remote(url: "https://github.com/pointfreeco/swift-composable-architecture", requirement: .upToNextMajor(from: "1.7.0")),
        .remote(url: "https://github.com/google/GoogleSignIn-iOS.git", requirement: .upToNextMajor(from: "7.0.0")),
        .remote(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", requirement: .upToNextMajor(from: "5.0.0")),
        .remote(url: "https://github.com/ReSwift/ReSwift.git", requirement: .upToNextMajor(from: "6.1.0")),
        .remote(url: "https://github.com/openid/AppAuth-iOS.git", requirement: .upToNextMajor(from: "1.6.2"))
    ],
    settings: .settings(
        base: [
            "DEVELOPMENT_TEAM": .string(developmentTeamId)
        ],
        configurations: [
            .debug(name: "Debug", settings: [:], xcconfig: nil),
            .release(name: "Release", settings: [:], xcconfig: nil)
        ],
        defaultSettings: .recommended
    ),
    targets: [
        .target(
            name: "caringmind",
            destinations: destinations,
            product: .framework,
            bundleId: "\(bundleIdPrefix).framework",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Sources/caringmind/**"],
            dependencies: [
                .package(product: "ComposableArchitecture"),
                .package(product: "GoogleSignIn"),
                .package(product: "SwiftyJSON"),
                .package(product: "ReSwift"),
                .package(product: "AppAuth")
            ],
            settings: .settings(
                base: [
                    "GENERATE_INFOPLIST_FILE": "YES",
                    "OTHER_LDFLAGS": "$(inherited) -ObjC",
                    "ENABLE_BITCODE": "NO",
                    "SWIFT_INSTALL_OBJC_HEADER": "YES",
                    "CLANG_ENABLE_MODULES": "YES",
                    "INFOPLIST_KEY_CFBundleDisplayName": "CaringMind",
                    "INFOPLIST_KEY_UILaunchStoryboardName": "LaunchScreen",
                    "MARKETING_VERSION": .string(marketingVersion),
                    "CURRENT_PROJECT_VERSION": .string(currentProjectVersion)
                ]
            )
        ),
        .target(
            name: "CaringMindApp",
            destinations: destinations,
            product: .app,
            bundleId: "\(bundleIdPrefix).app",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Sources/CaringMindApp/**"],
            dependencies: [
                .target(name: "caringmind")
            ],
            settings: .settings(
                base: [
                    "GENERATE_INFOPLIST_FILE": "YES",
                    "INFOPLIST_KEY_UIApplicationSceneManifest_Generation": "YES",
                    "INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents": "YES",
                    "INFOPLIST_KEY_UILaunchScreen_Generation": "YES",
                    "MARKETING_VERSION": .string(marketingVersion),
                    "CURRENT_PROJECT_VERSION": .string(currentProjectVersion),
                    "DEVELOPMENT_TEAM": .string(developmentTeamId),
                    "CODE_SIGN_STYLE": "Automatic",
                    "INFOPLIST_KEY_CFBundleDisplayName": "CaringMind",
                    "ENABLE_BITCODE": "NO",
                    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
                    "CODE_SIGN_IDENTITY": "iPhone Developer",
                    "CODE_SIGN_ENTITLEMENTS": "Sources/CaringMindApp/CaringMindApp.entitlements"
                ]
            )
        )
    ],
    schemes: [
        Scheme(
            name: "CaringMindApp",
            shared: true,
            buildAction: .buildAction(targets: ["CaringMindApp"]),
            runAction: .runAction(configuration: "Debug"),
            archiveAction: .archiveAction(configuration: "Release"),
            profileAction: .profileAction(configuration: "Release"),
            analyzeAction: .analyzeAction(configuration: "Debug")
        ),
        Scheme(
            name: "CaringMindApp-Dev",
            shared: true,
            buildAction: .buildAction(targets: ["CaringMindApp"]),
            runAction: .runAction(
                configuration: "Debug",
                executable: "CaringMindApp",
                arguments: .init(environment: [
                    "SIMULATOR_DEVICE": .string(getEnvVar("SIMULATOR_DEVICE", default: "iPhone 16")),
                    "SIMULATOR_ID": .string(getEnvVar("SIMULATOR_ID", default: "BC6E19BF-3E95-4E02-82D1-E07968F483E2")),
                    "SIMULATOR_OS": .string(getEnvVar("SIMULATOR_OS", default: "18.1"))
                ])
            ),
            archiveAction: nil,
            profileAction: nil,
            analyzeAction: .analyzeAction(configuration: "Debug")
        )
    ]
)
