//
//  ContentView.swift
//  MLAIX iOS / iPadOS
//

import SwiftUI
import MLAIXShared
#if canImport(UIKit)
import UIKit
#endif

struct ContentView: View {
    @Environment(iOSChatState.self) private var chatState
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var showSettings = false
    @State private var hasAPI = SharedAPIConfig.shared.hasConfiguredAPI
    @State private var showConversationList = false
    @AppStorage("appearanceMode") private var appearanceModeRaw: String = "system"
    @AppStorage("appearanceAccentHex") private var accentHex: String = ""
    @AppStorage("appearanceFontScale") private var fontScaleRaw: Double = 1.0

    private var appearanceMode: ColorScheme? {
        switch appearanceModeRaw {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    private var resolvedAccentColor: Color? {
        guard !accentHex.isEmpty else { return nil }
        return Color(hex: accentHex)
    }

    var body: some View {
        Group {
            if hasAPI {
                if horizontalSizeClass == .regular {
                    iPadLayout
                } else {
                    iPhoneLayout
                }
            } else {
                SetupView(onDismiss: { hasAPI = SharedAPIConfig.shared.hasConfiguredAPI })
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onChange(of: showSettings) { _, isShowing in
            if !isShowing { hasAPI = SharedAPIConfig.shared.hasConfiguredAPI }
        }
        .onOpenURL { url in
            chatState.handleIncomingURL(url)
        }
        .preferredColorScheme(appearanceMode)
        .optionalTint(resolvedAccentColor)
        .scaleEffect((fontScaleRaw >= 0.8 && fontScaleRaw <= 1.3) ? fontScaleRaw : 1.0, anchor: .center)
    }

    // MARK: - iPad Layout (NavigationSplitView)

    private var iPadLayout: some View {
        @Bindable var state = chatState
        return NavigationSplitView {
            ConversationListView()
                .toolbar {
                    ToolbarItem(placement: .navigation) {
                        Button {
                            chatState.startNewConversation()
                        } label: {
                            Label("New Chat", systemImage: "plus.bubble")
                        }
                        .accessibilityLabel("New Chat")
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showSettings = true
                        } label: {
                            Label("Settings", systemImage: "gearshape")
                        }
                        .accessibilityLabel("Settings")
                    }
                }
        } detail: {
            NavigationStack {
                ChatView()
                    .navigationTitle(chatState.currentConversation?.title ?? "MLAIX")
            }
        }
    }

    // MARK: - iPhone Layout (NavigationStack + Sheet)

    private var iPhoneLayout: some View {
        NavigationStack {
            ChatView()
                .navigationTitle(chatState.currentConversation?.title ?? "MLAIX")
                .toolbar {
                    ToolbarItem(placement: .navigation) {
                        Button {
                            showConversationList = true
                        } label: {
                            Label("Conversations", systemImage: "list.bullet")
                        }
                        .accessibilityLabel("Conversations")
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Button {
                                chatState.startNewConversation()
                            } label: {
                                Label("New Chat", systemImage: "plus.bubble")
                            }
                            Button {
                                showSettings = true
                            } label: {
                                Label("Settings", systemImage: "gearshape")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                        .accessibilityLabel("Menu")
                    }
                }
                .sheet(isPresented: $showConversationList) {
                    NavigationStack {
                        ConversationListView(onSelect: {
                            showConversationList = false
                        })
                        .navigationTitle("Conversations")
                        .toolbar {
                            ToolbarItem(placement: .navigation) {
                                Button {
                                    chatState.startNewConversation()
                                    showConversationList = false
                                } label: {
                                    Label("New Chat", systemImage: "plus.bubble")
                                }
                            }
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") {
                                    showConversationList = false
                                }
                            }
                        }
                    }
                }
        }
    }
}

// MARK: - Conversation List View

struct ConversationListView: View {
    @Environment(iOSChatState.self) private var chatState
    var onSelect: (() -> Void)?

    var body: some View {
        List(selection: Binding(
            get: { chatState.selectedConversationId },
            set: { id in
                if let id { chatState.selectConversation(id) }
            }
        )) {
            ForEach(chatState.conversations) { conversation in
                Button {
                    chatState.selectConversation(conversation.id)
                    onSelect?()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(conversation.title)
                            .font(.headline)
                            .lineLimit(1)
                        HStack {
                            Text("\(conversation.messages.count) messages")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(conversation.lastUpdated, style: .relative)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .listRowBackground(
                    conversation.id == chatState.selectedConversationId
                        ? Color.accentColor.opacity(0.12)
                        : Color.clear
                )
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        chatState.deleteConversation(conversation.id)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .overlay {
            if chatState.conversations.isEmpty {
                ContentUnavailableView(
                    "No Conversations",
                    systemImage: "bubble.left.and.bubble.right",
                    description: Text("Tap + to start a new chat.")
                )
            }
        }
    }
}

// MARK: - Chat View

struct ChatView: View {
    @Environment(iOSChatState.self) private var chatState
    @State private var showErrorAlert = false

    var body: some View {
        VStack(spacing: 0) {
            MessagesList()
            InputBar()
        }
        .onChange(of: chatState.errorMessage) { _, newValue in
            showErrorAlert = newValue != nil
        }
        .onAppear {
            showErrorAlert = chatState.errorMessage != nil
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") {
                chatState.errorMessage = nil
                showErrorAlert = false
            }
            Button("Retry") {
                chatState.errorMessage = nil
                showErrorAlert = false
                chatState.retryLastMessage()
            }
        } message: {
            if let msg = chatState.errorMessage {
                Text(msg)
            }
        }
    }
}

// MARK: - Messages List

struct MessagesList: View {
    @Environment(iOSChatState.self) private var chatState

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    if chatState.messages.isEmpty && !chatState.isGenerating {
                        SharedEmptyChatView()
                    }
                    ForEach(chatState.messages) { msg in
                        SharedMessageBubble(text: msg.text, isUser: msg.isUser)
                            .id(msg.id)
                    }
                    if chatState.isGenerating {
                        SharedLoadingIndicator()
                            .id("loading-indicator")
                    }
                }
                .padding()
            }
            .onChange(of: chatState.messages.count) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: chatState.messages.last?.text) { _, _ in
                // Scroll as streaming tokens arrive
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: chatState.isGenerating) { _, isGen in
                if isGen {
                    scrollToBottom(proxy: proxy)
                }
            }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        if chatState.isGenerating {
            withAnimation(.easeOut(duration: 0.15)) {
                proxy.scrollTo("loading-indicator", anchor: .bottom)
            }
        } else if let last = chatState.messages.last {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }
}

// MARK: - Input Bar

struct InputBar: View {
    @Environment(iOSChatState.self) private var chatState

    var body: some View {
        @Bindable var state = chatState
        HStack(alignment: .bottom, spacing: 12) {
            TextField("Message...", text: $state.inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .accessibilityLabel("Message input")
                .accessibilityHint("Type your message and tap send")
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .lineLimit(1...6)
                .disabled(chatState.isGenerating)
                .onSubmit { chatState.send() }

            Button {
                chatState.send()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(chatState.isGenerating ? Color.secondary : Color.accentColor)
            }
            .accessibilityLabel(chatState.isGenerating ? "Generating" : "Send message")
            .disabled(chatState.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || chatState.isGenerating)
        }
        .padding()
        .background(.bar)
    }
}

// MARK: - Setup View

struct SetupView: View {
    let onDismiss: () -> Void
    @State private var apiURL = ""
    @State private var apiKey = ""
    @State private var model = "gpt-4o-mini"

    private var isValidSetup: Bool {
        let trimmed = apiURL.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !apiKey.isEmpty,
              let url = URL(string: trimmed),
              url.scheme == "https" || url.scheme == "http" else { return false }
        return true
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("API Base URL (e.g. https://api.openai.com/v1)", text: $apiURL)
                        #if os(iOS)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        #endif
                    SecureField("API Key", text: $apiKey)
                    TextField("Model", text: $model)
                } header: {
                    Text("Remote API")
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        let trimmed = apiURL.trimmingCharacters(in: .whitespaces)
                        if !trimmed.isEmpty {
                            let valid = (URL(string: trimmed).map { $0.scheme == "https" || $0.scheme == "http" }) ?? false
                            if !valid {
                                Text("URL must be valid and start with https:// or http://")
                                    .foregroundStyle(.red)
                            }
                        }
                        Text("Configure your OpenAI-compatible API endpoint. Local models are not available on iOS.")
                    }
                }

                Section {
                    Button("Save & Continue") {
                        let trimmed = apiURL.trimmingCharacters(in: .whitespaces)
                        if let url = URL(string: trimmed), (url.scheme == "https" || url.scheme == "http"), !apiKey.isEmpty {
                            SharedAPIConfig.shared.apiBaseURL = url
                            SharedAPIConfig.shared.apiKey = apiKey
                            SharedAPIConfig.shared.model = model.isEmpty ? "gpt-4o-mini" : model
                            #if canImport(UIKit)
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            #endif
                            onDismiss()
                        }
                    }
                    .disabled(!isValidSetup)
                }
            }
            .navigationTitle("Setup")
            .onAppear {
                apiURL = SharedAPIConfig.shared.apiBaseURL?.absoluteString ?? ""
                apiKey = SharedAPIConfig.shared.apiKey ?? ""
                model = SharedAPIConfig.shared.model ?? "gpt-4o-mini"
            }
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var apiURL = ""
    @State private var apiKey = ""
    @State private var model = "gpt-4o-mini"
    @AppStorage("appearanceMode") private var appearanceModeRaw: String = "system"
    @AppStorage("appearanceAccentHex") private var accentHex: String = ""
    @AppStorage("appearanceThemePreset") private var themePresetRaw: String = ThemePreset.default.rawValue
    @AppStorage("appearanceFontScale") private var fontScaleRaw: Double = 1.0

    private var themePresetBinding: Binding<ThemePreset> {
        Binding(
            get: { ThemePreset(rawValue: themePresetRaw) ?? .default },
            set: {
                themePresetRaw = $0.rawValue
                accentHex = $0.accentHex
            }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Appearance", selection: $appearanceModeRaw) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .pickerStyle(.segmented)
                    Picker("Theme", selection: themePresetBinding) {
                        ForEach(ThemePreset.allCases) { preset in
                            HStack {
                                Circle()
                                    .fill(Color(hex: preset.accentHex))
                                    .frame(width: 10, height: 10)
                                Text(preset.displayName)
                            }
                            .tag(preset)
                        }
                    }
                    Toggle("Custom Accent Color", isOn: Binding(
                        get: { !accentHex.isEmpty },
                        set: { if !$0 { accentHex = "" } }
                    ))
                    if !accentHex.isEmpty {
                        ColorPicker("Accent Color", selection: Binding(
                            get: { Color(hex: accentHex) },
                            set: { if let h = $0.toHex { accentHex = h } }
                        ), supportsOpacity: true)
                    }
                    Picker("Font Size", selection: $fontScaleRaw) {
                        Text("Compact").tag(0.9)
                        Text("Default").tag(1.0)
                        Text("Large").tag(1.15)
                    }
                } header: {
                    Text("Appearance")
                }
                Section {
                    HStack {
                        Text("Acceleration")
                        Spacer()
                        Text("Remote API")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Compute")
                } footer: {
                    Text("On-device GPU and NPU are not used with remote API. Your API provider handles server-side acceleration.")
                }
                Section("API") {
                    TextField("API Base URL", text: $apiURL)
                        #if os(iOS)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        #endif
                    SecureField("API Key", text: $apiKey)
                    TextField("Model", text: $model)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        let trimmed = apiURL.trimmingCharacters(in: .whitespaces)
                        if trimmed.isEmpty {
                            SharedAPIConfig.shared.apiBaseURL = nil
                        } else if let url = URL(string: trimmed), url.scheme == "https" || url.scheme == "http" {
                            SharedAPIConfig.shared.apiBaseURL = url
                        }
                        SharedAPIConfig.shared.apiKey = apiKey.isEmpty ? nil : apiKey
                        SharedAPIConfig.shared.model = model.isEmpty ? "gpt-4o-mini" : model
                        dismiss()
                    }
                }
            }
            .onAppear {
                apiURL = SharedAPIConfig.shared.apiBaseURL?.absoluteString ?? ""
                apiKey = SharedAPIConfig.shared.apiKey ?? ""
                model = SharedAPIConfig.shared.model ?? "gpt-4o-mini"
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(iOSChatState())
}
