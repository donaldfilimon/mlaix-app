//
//  MLAIXApp.swift
//  MLAIX
//
//  Created by Bean John on 10/4/24.
//

import AppKit
import Foundation
import FSKit_macOS
import SwiftData
import SwiftUI
import TipKit

import class MLAIXShared.FunctionSelectionModel
import class MLAIXShared.SharedConversation
import class MLAIXShared.SharedChatMessage
import class MLAIXShared.MemoryModel
import class MLAIXShared.CommandModel
import class MLAIXShared.InferenceRecordModel
import class MLAIXShared.ServerArgumentModel

@main
struct MLAIApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @State private var appState: AppState = .shared
    @State private var downloadManager: DownloadManager = .shared
    @State private var conversationManager: ConversationManager = .shared
    @State private var expertManager: ExpertManager = .shared
    @State private var commandManager: CommandManager = .shared
    @State private var memories: Memories = .shared
    @State private var lengthyTasksController: LengthyTasksController = .shared
    @State private var modelManager: ModelManager = .shared
    @State private var inferenceRecords: InferenceRecords = .shared
    @State private var speechSynthesizer: SpeechSynthesizer = .shared
    @State private var serverArgumentsManager: ServerArgumentsManager = .shared
    @State private var inlineAssistantController: InlineAssistantController = .shared
    @State private var model: Model = .shared

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
    
    /// SwiftData model container shared across all windows.
    private let modelContainer: ModelContainer

    init() {
        // Hide all tips for now
        Tips.hideAllTipsForTesting()
        // Initialize model cache
        Task {
            let signpost = StartupMetrics.beginInterval("KnownModel.initializeModelCache")
            await KnownModel.initializeModelCache()
            StartupMetrics.endInterval("KnownModel.initializeModelCache", signpost)
        }
        // Configure SwiftData
        let schema = Schema([
            SharedConversation.self,
            SharedChatMessage.self,
            MemoryModel.self,
            CommandModel.self,
            InferenceRecordModel.self,
            ServerArgumentModel.self,
            FunctionSelectionModel.self
        ])
        let fileConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container: ModelContainer
        if let c = try? ModelContainer(for: schema, configurations: [fileConfig]) {
            container = c
        } else if let c = try? ModelContainer(for: schema, configurations: [memoryConfig]) {
            container = c
        } else {
            preconditionFailure("SwiftData container failed: disk and in-memory initialization both failed.")
        }
        self.modelContainer = container
        // Run one-time JSON → SwiftData migration
        let context = ModelContext(container)
        DataMigrationService.migrateIfNeeded(context: context)
    }
    
    var body: some Scene {
        
        // Main window
        WindowGroup {
			ContentView()
				.environment(appState)
				.environmentObject(downloadManager)
				.environment(conversationManager)
				.environment(expertManager)
				.environment(lengthyTasksController)
				.environment(memories)
				.environment(modelManager)
				.environment(inferenceRecords)
				.environmentObject(speechSynthesizer)
				.environment(serverArgumentsManager)
				.environment(inlineAssistantController)
				.environment(model)
				.environment(commandManager)
                .environment(\.liquidGlassStyle, liquidGlassStyle)
                .preferredColorScheme(appearanceMode.colorScheme)
                .optionalTint(resolvedAccentColor)
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
                .environment(memories)
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
                .environment(inferenceRecords)
        }
        
        // Window for Tool: Detector
        SwiftUI.Window("Detector", id: "detector") {
            DetectorView()
        }

        // Window for Tool: Diagrammer
        SwiftUI.Window("Diagrammer", id: "diagrammer") {
            DiagrammerView()
                .environment(model)
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
				.environment(commandManager)
				.environment(modelManager)
				.environmentObject(speechSynthesizer)
				.environment(serverArgumentsManager)
				.environmentObject(downloadManager)
		}
        
    }
    
}
