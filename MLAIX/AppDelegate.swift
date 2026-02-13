//
//  AppDelegate.swift
//  MLAI
//
//  Created by Bean John on 10/5/24.
//

import AppKit
import Foundation
import FSKit_macOS
import OSLog
import SwiftUI
import TipKit

/// The app's delegate which handles life cycle events
@MainActor
public class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {

    /// A object of type  ``InlineAssistantController`` controller
    let inlineAssistantController: InlineAssistantController = .shared
    /// A object of type  ``CompletionsController`` controller
    let completionsController: CompletionsController = .shared
    
    /// Function that runs after the app is initialized
    public func applicationDidFinishLaunching(
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
    
    /// Function that runs before the app is terminated
    public func applicationShouldTerminate(
        _ sender: NSApplication
    ) -> NSApplication.TerminateReply {
        // Flush pending conversation saves before shutdown
        ConversationManager.shared.saveNow()
        // Stop server
        Task {
            await Model.shared.stopServers()
        }
        // Remove stale sources
        SourcesManager.shared.removeStaleSources()
        // Remove non-persisted resources
        ExpertManager.shared.removeUnpersistedResources()
        return .terminateNow
    }
    
}

extension AppDelegate {
    
    @MainActor
    private func prepareInitialConversation() async {
        let conversationManager = ConversationManager.shared
        while !conversationManager.isLoaded {
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
        conversationManager.ensureBlankConversationForLaunch()
    }
    
}
