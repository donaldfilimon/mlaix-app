//
//  ConversationManagerView.swift
//  MLAI
//
//  Created by Bean John on 10/8/24.
//

import Combine
import SwiftUI

struct ConversationManagerView: View {
    
    @Environment(\.appearsActive) private var appearsActive
    @Environment(\.colorScheme) private var colorScheme
    
    @AppStorage("remoteModelName") private var serverModelName: String = InferenceSettings.serverModelName
    
    @EnvironmentObject private var model: Model
    @StateObject private var canvasController: CanvasController = .init()
    
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var expertManager: ExpertManager
    @EnvironmentObject private var conversationManager: ConversationManager
    @Environment(ConversationState.self) private var conversationState
    
    var selectedExpert: Expert? {
        guard let selectedExpertId = conversationState.selectedExpertId else {
            return nil
        }
        return expertManager.getExpert(id: selectedExpertId)
    }
    
    var toolbarTextColor: Color {
        guard let selectedExpert = selectedExpert else {
            return .primary
        }
        // Use the same logic as expert label/icon for consistency
        return selectedExpert.color.adaptedTextColor
    }
    
    var selectedConversation: Conversation? {
        guard let selectedConversationId = conversationState.selectedConversationId else {
            return nil
        }
        return self.conversationManager.getConversation(
            id: selectedConversationId
        )
    }
    
    var body: some View {
        NavigationSplitView {
            conversationList
        } detail: {
            conversationView
        }
        .navigationTitle("")
        .toolbar {
            ToolbarItem(id: "model", placement: .navigation) {
                ModelSelectorDropdown(serverModelName: self.$serverModelName)
            }
            ToolbarItem(id: "experts", placement: .principal) {
                ExpertSelectionMenu()
                    .onChange(of: conversationState.selectedExpertId, initial: false) { _, _ in
                        guard var selectedConversation = self.selectedConversation else { return }
                        selectedConversation.expertId = self.conversationState.selectedExpertId
                        self.conversationManager.update(selectedConversation)
                    }
            }
            ToolbarItem(id: "canvas", placement: .primaryAction) {
                canvasToggle
            }
            ToolbarItem(id: "share", placement: .primaryAction) {
                MessageShareMenu()
            }
        }
        .toolbarBackground(.visible, for: .windowToolbar)
        .if(selectedExpert != nil) { view in
            guard let expert = selectedExpert else {
                return AnyView(view)
            }
            return AnyView(
                view
                    .toolbarBackground(
                        expert.color,
                        for: .windowToolbar
                    )
            )
        }
        .onChange(of: selectedExpert, initial: false) { _, _ in
            self.refreshSystemPrompt()
        }
        .onChange(of: conversationState.selectedConversationId) { _, _ in
            withAnimation(.linear) {
                // Use most recently selected expert
                let expertId: UUID? = selectedConversation?.messages.last?.expertId ?? expertManager.default?.id
                self.conversationState.selectedExpertId = expertId
                // Turn off artifacts
                self.conversationState.useCanvas = false
            }
        }
        .onChange(of: self.selectedConversation?.messagesWithSnapshots) { _, _ in
            self.loadLatestSnapshot()
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: Notifications.systemPromptChanged.name
            )
        ) { output in
            self.refreshSystemPrompt()
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: Notifications.changedInferenceConfig.name
            )
        ) { output in
            self.refreshModel()
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: Notifications.newConversation.name
            )
        ) { output in
            withAnimation(.linear) {
                self.conversationState.selectedExpertId = expertManager.default?.id
            }
            if let recentConversationId = conversationManager.recentConversation?.id {
                withAnimation(.linear) {
                    self.conversationState.selectedConversationId = recentConversationId
                }
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: Notifications.switchToConversation.name
            )
        ) { output in
            guard let targetId = output.object as? UUID else {
                return
            }
            withAnimation(.linear) {
                self.conversationState.selectedConversationId = targetId
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notifications.toggleCanvas.name)) { _ in
            self.toggleCanvas()
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: Notifications.didCommandSelectExpert.name
            )
        ) { output in
            // Update expert if needed
            if self.appearsActive {
                withAnimation(.linear) {
                    self.conversationState.selectedExpertId = self.appState.commandSelectedExpertId
                }
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: NSApplication.willTerminateNotification
            )
        ) { output in
            /// Stop server before app is quit
            Task {
                await self.model.stopServers()
            }
        }
        .environmentObject(model)
        .environmentObject(canvasController)
    }
    
    var conversationList: some View {
        VStack(
            alignment: .leading,
            spacing: 3
        ) {
            ConversationNavigationListView()
            Spacer()
            ConversationSidebarButtons()
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 8)
        .liquidGlassPanel(cornerRadius: 16)
        .padding(.leading, 6)
    }
    
    var conversationView: some View {
        Group {
            if conversationState.selectedConversationId == nil || selectedConversation == nil {
                noSelectedConversation
            } else {
                HSplitView {
                    ConversationView()
                        .frame(minWidth: 450, minHeight: 500)
                    if self.conversationState.useCanvas {
                        CanvasView()
                            .frame(
                                minWidth: 500,
                                idealWidth: 700,
                                maxWidth: 800
                            )
                    }
                }
            }
        }
    }
    
    var noSelectedConversation: some View {
        HStack {
            Text("Hit")
            Button {
                self.conversationState.newConversation()
            } label: {
                Text("Command ⌘ + N")
            }
            Text("to start a conversation.")
        }
        .liquidGlassPanel(cornerRadius: 16)
        .padding()
    }
    
    var canvasToggle: some View {
        Button {
            self.toggleCanvas()
        } label: {
            Label("Canvas", systemImage: "cube")
                .foregroundStyle(toolbarTextColor)
                .symbolRenderingMode(.monochrome)
        }
        .disabled({
            let hasAssistantMessages = self.selectedConversation?.messages.contains {
                $0.getSender() == .assistant
            } ?? false
            let hasMessages = !(self.selectedConversation?.messages.isEmpty ?? true)
            return !hasAssistantMessages || !hasMessages
        }())
        .keyboardShortcut(.return, modifiers: [.command, .option])
    }
    
    /// Function to load latest snapshot
    private func loadLatestSnapshot() {
        // Get latest message message with snapshot
        guard let selectedConversation = self.selectedConversation else {
            return
        }
        guard let message = selectedConversation.messagesWithSnapshots.last else {
            return
        }
        // Show latest snapshot in canvas
        withAnimation(.linear) {
            self.canvasController.selectedMessageId = message.id
            self.conversationState.useCanvas = true
        }
    }
    
    private func toggleCanvas() {
        withAnimation(.linear) {
            // Select a version if possible
            if let message = self.selectedConversation?.messagesWithSnapshots.last {
                self.canvasController.selectedMessageId = message.id
            }
            // Confirm whether content should be extracted
            if self.selectedConversation?.messagesWithSnapshots.isEmpty ?? true {
                // If no snapshots, confirm extraction
                if !Dialogs.showConfirmation(
                    title: String(localized: "No Content Found"),
                    message: String(localized: "No content found. Would you like to extract content from your most recent message?")
                ) {
                    return // If no, exit
                }
            }
            // Toggle canvas
            self.conversationState.useCanvas.toggle()
            // Extract snapshot if needed
            if !self.canvasController.isExtractingSnapshot {
                Task { @MainActor in
                    try? await self.canvasController.extractSnapshot(
                        selectedConversation: selectedConversation
                    )
                }
            }
        }
    }
    
    private func refreshModel() {
        // Refresh model
        Task {
            await self.model.refreshModel()
        }
    }
    
    private func refreshSystemPrompt() {
        // Set new prompt
        var prompt: String = InferenceSettings.systemPrompt
        if let systemPrompt = self.selectedExpert?.systemPrompt {
            prompt = systemPrompt
        }
        Task {
            await self.model.setSystemPrompt(prompt)
        }
    }
    
}
