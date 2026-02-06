//
//  MLAIXApp.swift
//  MLAIX
//
//  Created by Bean John on 10/4/24.
//

import AppKit
import Foundation
import FSKit_macOS
import SwiftUI
import TipKit

@main
struct MLAIApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var appState: AppState = .shared
    @StateObject private var downloadManager: DownloadManager = .shared
    @StateObject private var conversationManager: ConversationManager = .shared
    @StateObject private var expertManager: ExpertManager = .shared
    @StateObject private var commandManager: CommandManager = .shared
    @StateObject private var memories: Memories = .shared
    @StateObject private var lengthyTasksController: LengthyTasksController = .shared
    @StateObject private var modelManager: ModelManager = .shared
    @StateObject private var inferenceRecords: InferenceRecords = .shared
    @StateObject private var speechSynthesizer: SpeechSynthesizer = .shared
    @StateObject private var serverArgumentsManager: ServerArgumentsManager = .shared
    @StateObject private var inlineAssistantController: InlineAssistantController = .shared
    @StateObject private var model: Model = .shared

    @AppStorage("appearanceMode") private var appearanceModeRaw: String = AppearanceSettings.AppearanceMode.system.rawValue
    @AppStorage("appearanceAccentHex") private var accentHex: String = ""
    @AppStorage("appearanceFontScale") private var fontScaleRaw: Double = AppearanceSettings.FontScale.default.rawValue

    @AppStorage("appearanceLiquidGlassEnabled") private var liquidGlassEnabled: Bool = LiquidGlassStyle.default.isEnabled
    @AppStorage("appearanceGlassMaterial") private var glassMaterialRaw: String = LiquidGlassStyle.default.materialStyle.rawValue
    @AppStorage("appearanceTintHex") private var tintHex: String = LiquidGlassStyle.default.tintHex
    @AppStorage("appearanceHighlightHex") private var highlightHex: String = LiquidGlassStyle.default.highlightHex
    @AppStorage("appearanceGlassOpacity") private var glassOpacity: Double = LiquidGlassStyle.default.opacity
    @AppStorage("appearanceGlassCornerRadius") private var glassCornerRadius: Double = LiquidGlassStyle.default.cornerRadius

    private var appearanceMode: AppearanceSettings.AppearanceMode {
        AppearanceSettings.AppearanceMode(rawValue: appearanceModeRaw) ?? .system
    }

    private var resolvedAccentColor: Color? {
        guard !accentHex.isEmpty else { return nil }
        return Color(hex: accentHex)
    }

    private var liquidGlassStyle: LiquidGlassStyle {
        let materialStyle = LiquidGlassStyle.MaterialStyle(rawValue: glassMaterialRaw) ?? .ultraThin
        return LiquidGlassStyle(
            isEnabled: liquidGlassEnabled,
            materialStyle: materialStyle,
            tintHex: tintHex,
            highlightHex: highlightHex,
            opacity: glassOpacity,
            cornerRadius: glassCornerRadius
        )
    }
    
    init() {
        // Hide all tips for now
        Tips.hideAllTipsForTesting()
        // Initialize model cache
        Task {
            let signpost = StartupMetrics.begin("KnownModel.initializeModelCache")
            await KnownModel.initializeModelCache()
            StartupMetrics.end("KnownModel.initializeModelCache", signpost)
        }
    }
    
    var body: some Scene {
        
        // Main window
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(downloadManager)
                .environmentObject(conversationManager)
                .environmentObject(expertManager)
                .environmentObject(lengthyTasksController)
                .environmentObject(memories)
                .environmentObject(modelManager)
                .environmentObject(inferenceRecords)
                .environmentObject(speechSynthesizer)
                .environmentObject(serverArgumentsManager)
                .environmentObject(inlineAssistantController)
                .environmentObject(model)
                .environmentObject(commandManager)
                .environment(\.liquidGlassStyle, liquidGlassStyle)
                .preferredColorScheme(appearanceMode.colorScheme)
                .modifier(OptionalTintModifier(color: resolvedAccentColor))
                .modifier(FontScaleModifier(scale: fontScaleRaw))
                .liquidGlassWindow()
        }
        .windowToolbarStyle(.unified)
        .defaultSize(width: 1000, height: 700)
        .commands {
            ConversationCommands.commands
            ConversationCommands.expertCommands
            ChatCommands.commands
            WindowCommands.commands
            // Command replacing the help button
            HelpCommands.helpCommand
            #if DEBUG
            // Commands useful for debugging (hidden in release)
            DebugCommands.commands
            #endif
            // Commands to obtain help and report problems
            HelpCommands.commands
        }
        
        // Window for managing memories
        SwiftUI.Window("Memory", id: "memory") {
            MemoriesManagerView()
                .environmentObject(memories)
                .frame(minWidth: 500, maxWidth: 600, maxHeight: 550)
        }
        .windowResizability(.contentSize)
        .windowIdealSize(.fitToContent)
        
        // Window for Tool: Models
        SwiftUI.Window("Models", id: "models") {
            ModelExplorerView()
        }
        
        // Window for Tool: Dashboard
        SwiftUI.Window("Dashboard", id: "dashboard") {
            DashboardView()
                .environmentObject(inferenceRecords)
        }
        
        // Window for Tool: Detector
        SwiftUI.Window("Detector", id: "detector") {
            DetectorView()
        }

        // Window for Tool: Diagrammer
        SwiftUI.Window("Diagrammer", id: "diagrammer") {
            DiagrammerView()
                .environmentObject(model)
        }

        // Window for Tool: Slide Studio
        SwiftUI.Window("Slide Studio", id: "slideStudio") {
            SlideStudioView()
        }
        
        // Keyboard Shortcuts reference
        SwiftUI.Window("Keyboard Shortcuts", id: "keyboardShortcuts") {
            KeyboardShortcutsView()
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        #if DEBUG
        // Script Testing (JavaScriptCore + WebView) — debug only
        SwiftUI.Window("Script Testing", id: "scriptTesting") {
            ScriptTestingView()
                .frame(minWidth: 640, minHeight: 400)
        }
        .windowResizability(.contentSize)
        #endif

        // Settings window
        SwiftUI.Settings {
            SettingsView()
                .environmentObject(commandManager)
                .environmentObject(modelManager)
                .environmentObject(speechSynthesizer)
                .environmentObject(serverArgumentsManager)
                .environmentObject(downloadManager)
        }
        
    }
    
}
