//
//  ConversationManagerView.swift
//  MLAI
//
//  Created by Bean John on 10/8/24.
//

import SwiftUI

struct ConversationManagerView: View {

    @Environment(\.appearsActive) private var appearsActive
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openWindow) private var openWindow

    @AppStorage("remoteModelName") private var serverModelName: String = InferenceSettings.serverModelName

    @Environment(Model.self) private var model
    @State private var canvasController: CanvasController = .init()
    @State private var selectedPrimarySection: PrimarySection? = .conversations
    @State private var selectedToolId: String?
    @State private var showToolbox: Bool = false

    @Environment(AppState.self) private var appState
    @Environment(ExpertManager.self) private var expertManager
    @Environment(ConversationManager.self) private var conversationManager
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
            PrimarySidebarView(selection: $selectedPrimarySection)
        } content: {
            NavigationContentColumn(
                section: selectedPrimarySection,
                selectedToolId: $selectedToolId
            )
        } detail: {
            NavigationDetailColumn(
                section: selectedPrimarySection,
                selectedToolId: selectedToolId,
                conversationView: { AnyView(conversationView) },
                noConversationView: { AnyView(noSelectedConversation) }
            )
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
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    self.conversationState.newConversation()
                } label: {
                    Label("New Conversation", systemImage: "square.and.pencil")
                }
                .buttonStyle(.plain)
                .keyboardShortcut("n", modifiers: .command)
                .help("New Conversation (⌘N)")
                .accessibilityIdentifier("toolbar.newConversation")
                Button {
                    showToolbox = true
                } label: {
                    Label("Toolbox", systemImage: "wrench.and.screwdriver")
                }
                .buttonStyle(.plain)
                .keyboardShortcut("t", modifiers: .command)
                .help("Toolbox (⌘T)")
                .accessibilityIdentifier("toolbar.toolbox")
                canvasToggle
                MessageShareMenu()
                Menu {
                    Button {
                        NavigationState.shared.showKeyboardShortcutsRequested = true
                    } label: {
                        Label("Keyboard Shortcuts", systemImage: "keyboard")
                    }
                    .keyboardShortcut("k", modifiers: [.command, .shift])
                    SettingsLink {
                        Label("Settings…", systemImage: "gearshape")
                    }
                    .keyboardShortcut(",", modifiers: .command)
                } label: {
                    Label("More", systemImage: "ellipsis.circle")
                }
                .help("More actions")
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
        .onChange(of: NavigationState.shared.systemPromptChanged) { _, newValue in
            guard newValue else { return }
            self.refreshSystemPrompt()
            NavigationState.shared.systemPromptChanged = false
        }
        .onChange(of: NavigationState.shared.inferenceConfigChanged) { _, newValue in
            guard newValue else { return }
            self.refreshModel()
            NavigationState.shared.inferenceConfigChanged = false
        }
        .onChange(of: NavigationState.shared.newConversationRequested) { _, newValue in
            guard newValue else { return }
            withAnimation(.linear) {
                self.conversationState.selectedExpertId = expertManager.default?.id
            }
            if let recentConversationId = conversationManager.recentConversation?.id {
                withAnimation(.linear) {
                    self.conversationState.selectedConversationId = recentConversationId
                }
            }
            NavigationState.shared.newConversationRequested = false
        }
        .onChange(of: NavigationState.shared.switchToConversationId) { _, newValue in
            guard let targetId = newValue else { return }
            withAnimation(.linear) {
                self.conversationState.selectedConversationId = targetId
            }
            NavigationState.shared.switchToConversationId = nil
        }
        .onChange(of: NavigationState.shared.toggleCanvasRequested) { _, newValue in
            guard newValue else { return }
            self.toggleCanvas()
            NavigationState.shared.toggleCanvasRequested = false
        }
        .onChange(of: NavigationState.shared.commandSelectedExpertId) { _, newValue in
            // Update expert if needed
            if self.appearsActive {
                withAnimation(.linear) {
                    self.conversationState.selectedExpertId = self.appState.commandSelectedExpertId
                }
            }
            NavigationState.shared.commandSelectedExpertId = nil
        }
        .onChange(of: NavigationState.shared.showToolboxRequested) { _, newValue in
            guard newValue else { return }
            showToolbox = true
            NavigationState.shared.showToolboxRequested = false
        }
        .sheet(isPresented: $showToolbox) {
            ToolboxLibraryView(isPresented: $showToolbox)
                .frame(maxWidth: 500, minHeight: 600)
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
        .environment(model)
        .environment(canvasController)
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
        VStack(spacing: 28) {
            ContentUnavailableView(
                "No conversation selected",
                systemImage: "bubble.left.and.text.bubble.right",
                description: Text("Start a new chat or pick one from the list.")
            )
            .symbolVariant(.fill)
            Button {
                self.conversationState.newConversation()
            } label: {
                Label("New Conversation", systemImage: "square.and.pencil")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut("n", modifiers: .command)
            .accessibilityIdentifier("noConversation.newConversationButton")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.quaternary, lineWidth: 0.5)
        )
        .padding(24)
        .accessibilityIdentifier("noConversationSelected")
    }
    
    var canvasToggle: some View {
        Button {
            self.toggleCanvas()
        } label: {
            Label("Canvas", systemImage: "cube")
                .foregroundStyle(toolbarTextColor)
                .symbolRenderingMode(.monochrome)
        }
        .buttonStyle(.plain)
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
