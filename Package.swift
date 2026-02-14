// swift-tools-version: 6.3
import PackageDescription

// MARK: - Platform Configuration

/// All platforms require version 26 (macOS 26, iOS 26, iPadOS 26, tvOS 26, watchOS 26).
let supportedPlatforms: [SupportedPlatform] = [
    .macOS(.v26),
    .iOS(.v26),
    .watchOS(.v26),
    .visionOS(.v26),
    .tvOS(.v26),
]

// MARK: - Resources

private let llamaBin = "Logic/Inference/llama.cpp/build/bin/"

let package = Package(
    name: "MLAIX",
    defaultLocalization: "en",
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
        .package(url: "https://github.com/tmandry/AXSwift/", branch: "main"),
        .package(url: "https://github.com/mchakravarty/CodeEditorView", branch: "main"),
        .package(url: "https://github.com/johnbean393/Default-Models", branch: "main"),
        .package(url: "https://github.com/johnbean393/EventSource", branch: "main"),
        .package(url: "https://github.com/johnbean393/ExtractKit-macOS", branch: "main"),
        .package(url: "https://github.com/johnbean393/FSKit-macOS", branch: "main"),
        .package(url: "https://github.com/johnbean393/GoogleSearch", branch: "main"),
        .package(url: "https://github.com/raspu/Highlightr", branch: "master"),
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", branch: "main"),
        .package(url: "https://github.com/colinc86/LaTeXSwiftUI", branch: "main"),
        .package(url: "https://github.com/sindresorhus/LaunchAtLogin-Modern", branch: "main"),
        .package(url: "https://github.com/vpeschenkov/SecureDefaults", branch: "master"),
        .package(url: "https://github.com/donaldfilimon/similarity-search-kit", branch: "main"),
        .package(url: "https://github.com/JohnSundell/Splash", branch: "master"),
        .package(url: "https://github.com/stephencelis/SQLite.swift", branch: "master"),
        .package(url: "https://github.com/SwiftfulThinking/SwiftfulLoadingIndicators", branch: "main"),
        .package(url: "https://github.com/markiv/SwiftUI-Shimmer", branch: "main"),
        .package(url: "https://github.com/xnth97/SymbolPicker", branch: "main"),
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui", branch: "main"),
        .package(url: "https://github.com/gonzalezreal/NetworkImage", branch: "main"),
        .package(url: "https://github.com/danielsaidi/WebViewKit", branch: "main"),
        .package(url: "https://github.com/ml-explore/mlx-swift-lm", branch: "main")
    ],
    targets: [

        // MARK: - MLAIXShared (Unified SwiftUI + SwiftData across platforms)
        .target(
            name: "MLAIXShared",
            dependencies: [
                .product(name: "MarkdownUI", package: "swift-markdown-ui")
            ],
            path: "MLAIXShared"
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
                "Logic/Inference/Router/UserRequestClassifier.mlmodel",
                "Info.plist",
                "MLAIX.icon"
            ],
            resources: [
                .process("Assets.xcassets"),
                .process("Resources"),
                .process("Localizable.xcstrings"),
                .process("Credits.html"),
                .copy("Logic/Inference/Router/UserRequestClassifier.mlmodelc"),
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
            ]
        ),

        // MARK: - MLAIXiOS (iOS / iPadOS App)
        .executableTarget(
            name: "MLAIXiOS",
            dependencies: ["MLAIXShared"],
            path: "MLAIXiOS",
            exclude: ["Info.plist"],
            resources: [.process("Assets.xcassets")]
        ),

        // MARK: - MLAIXtvOS (tvOS placeholder)
        .executableTarget(
            name: "MLAIXtvos",
            dependencies: ["MLAIXShared"],
            path: "MLAIXtvos"
        ),

        // MARK: - MLAIXWatch (Apple Watch companion)
        .executableTarget(
            name: "MLAIXWatch",
            dependencies: [],
            path: "MLAIXWatch"
        ),

        // MARK: - Watchdog
        .executableTarget(
            name: "llama-server-watchdog",
            path: "MLAIX/Logic/Inference/llama.cpp/llama-server-watchdog",
            exclude: [
                "llama-server-watchdog.entitlements"
            ]
        ),

        // MARK: - Tests
        .testTarget(
            name: "MLAIXTests",
            dependencies: ["MLAIX"],
            path: "MLAIXTests"
        ),
        .testTarget(
            name: "MLAIXiOSTests",
            dependencies: ["MLAIXiOS", "MLAIXShared"],
            path: "MLAIXiOSTests"
        ),
        .testTarget(
            name: "MLAIXSharedTests",
            dependencies: ["MLAIXShared"],
            path: "MLAIXSharedTests"
        ),
        .testTarget(
            name: "MLAIXUITests",
            dependencies: ["MLAIX"],
            path: "MLAIXUITests",
            exclude: ["README.md"]
        )
    ],
    swiftLanguageModes: [.v6]  // Swift 6.2 language mode
)
