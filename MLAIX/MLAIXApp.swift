//
//  MLAIXApp.swift
//  MLAIX
//
//  Created by Bean John on 10/4/24.

import AppKit
import Foundation
import FSKit_macOS
import OSLog
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

// MARK: - AppDelegate

/// The app's delegate which handles life cycle events
class AppDelegate: NSObject, NSApplicationDelegate {

    /// Function that runs after the app is initialized
    func applicationDidFinishLaunching(
        _ notification: Notification
    ) {
        Tips.hideAllTipsForTesting()
        Logger(subsystem: Bundle.main.logSubsystem, category: "AppDelegate").debug("Hid all tips")
        // Relocate legacy resources if setup finished
        if Settings.setupComplete {
            let signpost = StartupMetrics.beginInterval("Refactorer.refactor")
            Refactorer.refactor()
            StartupMetrics.endInterval("Refactorer.refactor", signpost)
        }
        // Configure Tip's data container
        try? Tips.configure(
            [
                .datastoreLocation(.applicationDefault),
                .displayFrequency(.daily)
            ]
        )
        // Configure keyboard shortcuts
        ShortcutController.setup()
        // Prepare an empty conversation for launch
        Task { @MainActor in
            await self.prepareInitialConversation()
        }
        // Update endpoint format
        Task { @MainActor in
            await Refactorer.updateEndpoint()
        }
        // Auto-configure backend when no model is set (e.g. first launch)
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            if await BackendAutoConfig.autoConfigureIfNeeded() {
                await Model.shared.refreshModel()
            }
        }
        // Make sure `Resources` are not indexing
        for expert in ExpertManager.shared.experts {
            var modExpert = expert
            if modExpert.resources.graphStatus != .ready {
                modExpert.resources.graphStatus = nil
                modExpert.resources.graphProgress = nil
            }
            ExpertManager.shared.update(modExpert)
        }
    }

    /// When the app becomes active, ensure a key window exists. Prefer the main (MLAIX) window when none is key.
    func applicationDidBecomeActive(_ notification: Notification) {
        if NSApp.keyWindow != nil {
            return
        }
        if let main = AppWindowManager.mainWindow {
            main.makeKeyAndOrderFront(self)
        } else {
            NSApp.windows.first { $0.canBecomeKey }?.makeKey()
        }
    }

    /// Provide the dock menu (right-click or control-click on the app icon in the dock).
    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        DockMenuCommands.makeDockMenu(target: self)
    }

    @MainActor @objc func dockNewConversation(_ sender: Any?) {
        NSApp.activate(ignoringOtherApps: true)
        ConversationManager.shared.newConversation()
    }

    @MainActor @objc func dockShowToolbox(_ sender: Any?) {
        NSApp.activate(ignoringOtherApps: true)
        NavigationState.shared.showToolboxRequested = true
    }

    @MainActor @objc func dockOpenSettings(_ sender: Any?) {
        NSApp.activate(ignoringOtherApps: true)
        if #available(macOS 14.0, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        }
    }

    /// Function that runs before the app is terminated
    func applicationShouldTerminate(
        _ sender: NSApplication
    ) -> NSApplication.TerminateReply {
        // Flush pending conversation saves before shutdown
        ConversationManager.shared.saveNow()
        // Remove stale sources
        SourcesManager.shared.removeStaleSources()
        // Remove non-persisted resources
        ExpertManager.shared.removeUnpersistedResources()
        // Stop server and reply when done
        Task { @MainActor in
            await Model.shared.stopServers()
            NSApp.reply(toApplicationShouldTerminate: true)
        }
        return .terminateLater
    }

}

extension AppDelegate {

    @MainActor
    func prepareInitialConversation() async {
        let conversationManager = ConversationManager.shared
        while !conversationManager.isLoaded {
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
        conversationManager.ensureBlankConversationForLaunch()
    }

}

// MARK: - MLAIApp

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
        // Run one-time JSON → SwiftData migration and expose container/context to app
        let context = ModelContext(container)
        DataMigrationService.migrateIfNeeded(context: context)
        SwiftDataStore.sharedContainer = container
        SwiftDataStore.mainContext = context
    }

    var body: some Scene {
        // Main window (supports multiple: Window > New Window or ⌘⇧N)
        WindowGroup(id: "main") {
			ContentView()
				.environment(appState)
				.environment(downloadManager)
				.environment(conversationManager)
				.environment(expertManager)
				.environment(lengthyTasksController)
				.environment(memories)
				.environment(modelManager)
				.environment(inferenceRecords)
				.environment(speechSynthesizer)
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

        // Window for managing memories
        SwiftUI.Window("Memory", id: "memory") {
            MemoriesManagerView()
                .environment(memories)
                .frame(minWidth: 500, maxWidth: 600, maxHeight: 550)
                .observeWindowCommands()
        }
        .windowResizability(.contentSize)
        .windowIdealSize(.fitToContent)

        // Window for Tool: Models
        SwiftUI.Window("Models", id: "models") {
            ModelExplorerView()
                .observeWindowCommands()
        }

        // Window for Tool: Dashboard
        SwiftUI.Window("Dashboard", id: "dashboard") {
            DashboardView()
                .environment(inferenceRecords)
                .observeWindowCommands()
        }

        // Window for Tool: Detector
        SwiftUI.Window("Detector", id: "detector") {
            DetectorView()
                .observeWindowCommands()
        }

        // Window for Tool: Diagrammer
        SwiftUI.Window("Diagrammer", id: "diagrammer") {
            DiagrammerView()
                .environment(model)
                .observeWindowCommands()
        }

        // Window for Tool: Slide Studio
        SwiftUI.Window("Slide Studio", id: "slideStudio") {
            SlideStudioView()
                .observeWindowCommands()
        }

        // Window for Tool: Node Editor (visual scripting)
        SwiftUI.Window("Node Editor", id: "nodeEditor") {
            NodeEditorView()
                .frame(minWidth: 720, minHeight: 480)
                .observeWindowCommands()
        }

        // Keyboard Shortcuts reference
        SwiftUI.Window("Keyboard Shortcuts", id: "keyboardShortcuts") {
            KeyboardShortcutsView()
                .observeWindowCommands()
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        #if DEBUG
        // Script Testing (JavaScriptCore + WebView) — debug only
        SwiftUI.Window("Script Testing", id: "scriptTesting") {
            ScriptTestingView()
                .frame(minWidth: 640, minHeight: 400)
                .observeWindowCommands()
        }
        .windowResizability(.contentSize)
        #endif

        // Settings window
		SwiftUI.Settings {
			SettingsView()
				.environment(commandManager)
				.environment(modelManager)
				.environment(speechSynthesizer)
				.environment(serverArgumentsManager)
				.environment(downloadManager)
		}

    }

}
