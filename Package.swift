// swift-tools-version: 6.2

import PackageDescription

// MARK: - Swift 6.2 Configuration

// /// Swift 6 strict concurrency; required for ralph-loop conc-002 (strict-concurrency build).
let swiftSettings: [SwiftSetting] = []

/// All platforms require version 26 (macOS 26, iOS 26, iPadOS 26, tvOS 26, watchOS 26).
let supportedPlatforms: [SupportedPlatform] = [
    .macOS(.v26)
]

// MARK: - Resources

private let llamaBin = "Logic/Inference/llama.cpp/build/bin/"

let package = Package(
    name: "MLAIX",
    platforms: supportedPlatforms,
    products: [
        .library(name: "MLAIXShared", targets: ["MLAIXShared"]),
        .executable(name: "MLAIX", targets: ["MLAIX"]),
        .executable(name: "MLAIXiOS", targets: ["MLAIXiOS"]),
        .executable(name: "MLAIXtvos", targets: ["MLAIXtvos"]),
        .executable(name: "MLAIXWatch", targets: ["MLAIXWatch"]),
        .executable(name: "llama-server-watchdog", targets: ["llama-server-watchdog"])
    ],
    dependencies: [
        .package(url: "https://github.com/tmandry/AXSwift/", from: "0.3.2"),
        .package(url: "https://github.com/mchakravarty/CodeEditorView", from: "0.15.3"),
        .package(url: "https://github.com/johnbean393/Default-Models", revision: "d5bc71875649c4febfba9b78b456b9cb6c90f23e"),
        .package(url: "https://github.com/johnbean393/EventSource", revision: "a6c5d1b77bf9161866e36b5c9f018871ff42f747"),
        .package(url: "https://github.com/johnbean393/ExtractKit-macOS", revision: "d2374e0fc535340fb2fe2f4825c5ae41035f4c7c"),
        .package(url: "https://github.com/johnbean393/FSKit-macOS", branch: "main"),
        .package(url: "https://github.com/johnbean393/GoogleSearch", revision: "8578671e3bc7277cff15949b142375ab581b216c"),
        .package(url: "https://github.com/raspu/Highlightr", from: "2.2.1"),
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.2.4"),
        .package(url: "https://github.com/colinc86/LaTeXSwiftUI", revision: "c45e0fd45f64923c49c5904a9f9626bc8939f05f"),
        .package(url: "https://github.com/sindresorhus/LaunchAtLogin-Modern", revision: "a04ec1c363be3627734f6dad757d82f5d4fa8fcc"),
        .package(url: "https://github.com/vpeschenkov/SecureDefaults", from: "1.2.2"),
        .package(url: "https://github.com/donaldfilimon/similarity-search-kit", revision: "759a31901768db084031031bdde0ad3f83ebea65"),
        .package(url: "https://github.com/JohnSundell/Splash", from: "0.16.0"),
        .package(url: "https://github.com/stephencelis/SQLite.swift", from: "0.15.4"),
        .package(url: "https://github.com/SwiftfulThinking/SwiftfulLoadingIndicators", from: "0.0.4"),
        .package(url: "https://github.com/markiv/SwiftUI-Shimmer", from: "1.5.1"),
        .package(url: "https://github.com/xnth97/SymbolPicker", from: "1.5.3"),
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui", from: "2.4.0"),
        .package(url: "https://github.com/gonzalezreal/NetworkImage", from: "6.0.1"),
        .package(url: "https://github.com/danielsaidi/WebViewKit", from: "0.5.0"),
        .package(url: "https://github.com/ml-explore/mlx-swift-lm", from: "2.30.3")
    ],
    targets: [

        // MARK: - MLAIXShared (Unified SwiftUI + SwiftData across platforms)
        .target(
            name: "MLAIXShared",
            dependencies: [
                .product(name: "MarkdownUI", package: "swift-markdown-ui")
            ],
            path: "MLAIXShared",
            swiftSettings: swiftSettings
        ),

        // MARK: - MLAIX (Main App)
        .executableTarget(
            name: "MLAIX",
            dependencies: [
                "MLAIXShared",
                .product(name: "AXSwift", package: "AXSwift"),
                .product(name: "CodeEditorView", package: "CodeEditorView"),
                .product(name: "LanguageSupport", package: "CodeEditorView"),
                .product(name: "DefaultModels", package: "Default-Models"),
                .product(name: "EventSource", package: "EventSource"),
                .product(name: "ExtractKit-macOS", package: "ExtractKit-macOS"),
                .product(name: "FSKit-macOS", package: "FSKit-macOS"),
                .product(name: "GoogleSearch", package: "GoogleSearch"),
                .product(name: "Highlightr", package: "Highlightr"),
                .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts"),
                .product(name: "LaTeXSwiftUI", package: "LaTeXSwiftUI"),
                .product(name: "LaunchAtLogin", package: "LaunchAtLogin-Modern"),
                .product(name: "SecureDefaults", package: "SecureDefaults"),
                .product(name: "SimilaritySearchKit", package: "similarity-search-kit"),
                .product(name: "Splash", package: "Splash"),
                .product(name: "SQLite", package: "SQLite.swift"),
                .product(name: "SwiftfulLoadingIndicators", package: "SwiftfulLoadingIndicators"),
                .product(name: "Shimmer", package: "SwiftUI-Shimmer"),
                .product(name: "SymbolPicker", package: "SymbolPicker"),
                .product(name: "MarkdownUI", package: "swift-markdown-ui"),
                .product(name: "NetworkImage", package: "NetworkImage"),
                .product(name: "WebViewKit", package: "WebViewKit"),
                .product(name: "MLXLLM", package: "mlx-swift-lm"),
                .product(name: "MLXLMCommon", package: "mlx-swift-lm")
            ],
            path: "MLAIX",
            exclude: [
                "Preview Content",
                "Logic/Inference/llama.cpp/llama-server-watchdog",
                "Info.plist",
                "MLAIX.entitlements",
                "MLAIX.icon"
            ],
            resources: [
                .process("Assets.xcassets"),
                .process("Resources"),
                .process("Localizable.xcstrings"),
                .process("Credits.html"),
                .process("Logic/Inference/Router/UserRequestClassifier.mlmodel"),
                .process("Logic/Utilities/Tools/MermaidRenderer/Resources"),
                .process("Logic/View Controllers/Tools/Slide Studio/Resources"),
                .copy("\(llamaBin)llama-server"),
                .copy("\(llamaBin)libggml.dylib"),
                .copy("\(llamaBin)libggml-base.dylib"),
                .copy("\(llamaBin)libggml-blas.dylib"),
                .copy("\(llamaBin)libggml-cpu.dylib"),
                .copy("\(llamaBin)libggml-metal.dylib"),
                .copy("\(llamaBin)libggml-rpc.dylib"),
                .copy("\(llamaBin)libllama.dylib"),
                .copy("\(llamaBin)libmtmd.dylib")
            ],
            swiftSettings: swiftSettings
        ),

        // MARK: - MLAIXiOS (iOS / iPadOS App)
        .executableTarget(
            name: "MLAIXiOS",
            dependencies: ["MLAIXShared"],
            path: "MLAIXiOS",
            exclude: ["Info.plist"],
            resources: [.process("Assets.xcassets")],
            swiftSettings: swiftSettings
        ),

        // MARK: - MLAIXtvOS (tvOS placeholder)
        .executableTarget(
            name: "MLAIXtvos",
            dependencies: ["MLAIXShared"],
            path: "MLAIXtvos",
            swiftSettings: swiftSettings
        ),

        // MARK: - MLAIXWatch (Apple Watch companion)
        .executableTarget(
            name: "MLAIXWatch",
            dependencies: [],
            path: "MLAIXWatch",
            swiftSettings: swiftSettings
        ),

        // MARK: - Watchdog
        .executableTarget(
            name: "llama-server-watchdog",
            path: "MLAIX/Logic/Inference/llama.cpp/llama-server-watchdog",
            exclude: [
                "llama-server-watchdog.entitlements"
            ],
            swiftSettings: swiftSettings
        ),

        // MARK: - Tests
        .testTarget(
            name: "MLAIXTests",
            dependencies: ["MLAIX"],
            path: "MLAIXTests",
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "MLAIXiOSTests",
            dependencies: ["MLAIXiOS", "MLAIXShared"],
            path: "MLAIXiOSTests",
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "MLAIXSharedTests",
            dependencies: ["MLAIXShared"],
            path: "MLAIXSharedTests",
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "MLAIXUITests",
            dependencies: ["MLAIX"],
            path: "MLAIXUITests",
            exclude: ["README.md"],
            swiftSettings: swiftSettings
        )
    ],
    swiftLanguageModes: [.v6]  // Swift 6.2 language mode
)
