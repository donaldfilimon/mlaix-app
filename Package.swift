// swift-tools-version: 6.2

import PackageDescription

let swiftSettings: [SwiftSetting] = {
    let settings: [SwiftSetting] = [
        .enableUpcomingFeature("StrictConcurrency")
    ]
    return settings
}()

let supportedPlatforms: [SupportedPlatform] = {
#if swift(>=6.2)
    return [.macOS(.v26)]
#else
    return [.macOS(.v15)]
#endif
}()

let package = Package(
    name: "MLAI",
    platforms: supportedPlatforms,
    products: [
        .executable(name: "MLAI", targets: ["MLAI"]),
        .executable(name: "llama-server-watchdog", targets: ["llama-server-watchdog"])
    ],
    dependencies: [
        .package(url: "https://github.com/tmandry/AXSwift/", from: "0.3.2"),
        .package(url: "https://github.com/mchakravarty/CodeEditorView", from: "0.15.3"),
        .package(url: "https://github.com/johnbean393/Default-Models", branch: "main"),
        .package(url: "https://github.com/johnbean393/EventSource", branch: "main"),
        .package(url: "https://github.com/johnbean393/ExtractKit-macOS", branch: "main"),
        .package(url: "https://github.com/johnbean393/FSKit-macOS", branch: "main"),
        .package(url: "https://github.com/johnbean393/GoogleSearch", branch: "main"),
        .package(url: "https://github.com/raspu/Highlightr", from: "2.2.1"),
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.2.4"),
        .package(url: "https://github.com/colinc86/LaTeXSwiftUI", branch: "main"),
        .package(url: "https://github.com/sindresorhus/LaunchAtLogin-Modern", branch: "main"),
        .package(url: "https://github.com/vpeschenkov/SecureDefaults", from: "1.2.2"),
        .package(url: "https://github.com/johnbean393/similarity-search-kit", branch: "main"),
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.4"),
        .package(url: "https://github.com/JohnSundell/Splash", from: "0.16.0"),
        .package(url: "https://github.com/stephencelis/SQLite.swift", from: "0.15.4"),
        .package(url: "https://github.com/SwiftfulThinking/SwiftfulLoadingIndicators", from: "0.0.4"),
        .package(url: "https://github.com/markiv/SwiftUI-Shimmer", from: "1.5.1"),
        .package(url: "https://github.com/SwiftUIX/SwiftUIX", from: "0.2.4"),
        .package(url: "https://github.com/xnth97/SymbolPicker", from: "1.5.3"),
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui", from: "2.4.0"),
        .package(url: "https://github.com/gonzalezreal/NetworkImage", from: "6.0.1"),
        .package(url: "https://github.com/danielsaidi/WebViewKit", from: "0.5.0")
    ],
    targets: [

        // MARK: - MLAI (Main App)
        .executableTarget(
            name: "MLAI",
            dependencies: [
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
                .product(name: "Sparkle", package: "Sparkle"),
                .product(name: "Splash", package: "Splash"),
                .product(name: "SplashMarkdown", package: "Splash"),
                .product(name: "SQLite", package: "SQLite.swift"),
                .product(name: "SwiftfulLoadingIndicators", package: "SwiftfulLoadingIndicators"),
                .product(name: "Shimmer", package: "SwiftUI-Shimmer"),
                .product(name: "SwiftUIX", package: "SwiftUIX"),
                .product(name: "SymbolPicker", package: "SymbolPicker"),
                .product(name: "MarkdownUI", package: "swift-markdown-ui"),
                .product(name: "NetworkImage", package: "NetworkImage"),
                .product(name: "WebViewKit", package: "WebViewKit")
            ],
            path: "Sidekick",
            exclude: [
                "Preview Content",
                "Logic/Inference/llama.cpp/llama-server-watchdog",
                "Views/Chat/Conversation/ChatStyle.swift",
                "Info.plist",
                "Sidekick.entitlements",
                "Sidekick.icon",
                "Logic/Inference/llama.cpp/build/bin/llama-perplexity"
            ],
            resources: [
                .process("Assets.xcassets"),
                .process("Resources"),
                .process("Localizable.xcstrings"),
                .process("Credits.html"),
                .process("Logic/Inference/Router/UserRequestClassifier.mlmodel"),
                .process("Logic/Utilities/Tools/MermaidRenderer/Resources"),
                .process("Logic/View Controllers/Tools/Slide Studio/Resources"),
                .copy("Logic/Inference/llama.cpp/build/bin/llama-server"),
                .copy("Logic/Inference/llama.cpp/build/bin/libggml.dylib"),
                .copy("Logic/Inference/llama.cpp/build/bin/libggml-base.dylib"),
                .copy("Logic/Inference/llama.cpp/build/bin/libggml-blas.dylib"),
                .copy("Logic/Inference/llama.cpp/build/bin/libggml-cpu.dylib"),
                .copy("Logic/Inference/llama.cpp/build/bin/libggml-metal.dylib"),
                .copy("Logic/Inference/llama.cpp/build/bin/libggml-rpc.dylib"),
                .copy("Logic/Inference/llama.cpp/build/bin/libllama.dylib"),
                .copy("Logic/Inference/llama.cpp/build/bin/libmtmd.dylib")
            ],
            swiftSettings: swiftSettings
        ),

        // MARK: - Watchdog
        .executableTarget(
            name: "llama-server-watchdog",
            path: "Sidekick/Logic/Inference/llama.cpp/llama-server-watchdog",
            exclude: [
                "llama-server-watchdog.entitlements"
            ],
            swiftSettings: swiftSettings
        ),

        // MARK: - Tests
        .testTarget(
            name: "MLAITests",
            dependencies: ["MLAI"],
            path: "SidekickTests",
            swiftSettings: swiftSettings
        )
    ],
    // Swift 5 mode for compatibility during migration
    swiftLanguageModes: [.v5]
)
