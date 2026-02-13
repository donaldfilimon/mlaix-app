//
//  MLAIXWatchApp.swift
//  MLAIX Apple Watch companion
//

import SwiftUI
#if os(watchOS)
import WatchConnectivity
#endif

// MARK: - App Entry Point

@main
struct MLAIXWatchApp: App {
    @State private var chatState = watchOSChatState()
    #if os(watchOS)
    @WKApplicationDelegateAdaptor private var appDelegate: WatchAppDelegate
    #endif

    var body: some Scene {
        WindowGroup {
            watchOSContentView()
                .environment(chatState)
                #if os(watchOS)
                .onAppear {
                    appDelegate.chatState = chatState
                }
                #endif
        }
    }
}

#if os(watchOS)
// MARK: - WatchConnectivity App Delegate

/// Handles WatchConnectivity session for communicating with the paired iPhone.
final class WatchAppDelegate: NSObject, WKApplicationDelegate, WCSessionDelegate {
    var chatState: watchOSChatState?

    func applicationDidFinishLaunching() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    // MARK: WCSessionDelegate

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: (any Error)?
    ) {
        // Session activated
    }

    /// Handle messages from the paired iPhone.
    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        if let reply = message["reply"] as? String {
            Task { @MainActor in
                chatState?.receiveReply(reply)
            }
        }
        replyHandler(["status": "ok"])
    }

    /// Handle userInfo transfers from the paired iPhone.
    func session(
        _ session: WCSession,
        didReceiveUserInfo userInfo: [String: Any]
    ) {
        if let reply = userInfo["reply"] as? String {
            Task { @MainActor in
                chatState?.receiveReply(reply)
            }
        }
    }
}
#endif

// MARK: - Chat State

/// Lightweight chat state for watchOS — can use WatchConnectivity or direct API calls.
@Observable
@MainActor
final class watchOSChatState {

    struct ChatMessage: Identifiable {
        let id = UUID()
        let text: String
        let isUser: Bool
        let date = Date()
    }

    var messages: [ChatMessage] = []
    var isLoading: Bool = false
    var errorMessage: String?

    /// Whether the paired iPhone is reachable via WatchConnectivity.
    private var isPhoneReachable: Bool {
        #if os(watchOS)
        return WCSession.default.isReachable
        #else
        return false
        #endif
    }

    // MARK: - Stored API config (standalone, no MLAIXShared dependency)

    private let defaults = UserDefaults.standard
    private let keyPrefix = "com.donaldfilimon.mlaix.watch"

    var apiBaseURL: String {
        get { defaults.string(forKey: "\(keyPrefix).apiBaseURL") ?? "" }
        set { defaults.set(newValue, forKey: "\(keyPrefix).apiBaseURL") }
    }

    var apiKey: String {
        get { defaults.string(forKey: "\(keyPrefix).apiKey") ?? "" }
        set { defaults.set(newValue, forKey: "\(keyPrefix).apiKey") }
    }

    var model: String {
        get { defaults.string(forKey: "\(keyPrefix).model") ?? "gpt-4o-mini" }
        set { defaults.set(newValue, forKey: "\(keyPrefix).model") }
    }

    var hasAPIConfig: Bool {
        !apiBaseURL.isEmpty && !apiKey.isEmpty
    }

    // MARK: - Send

    func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isLoading else { return }

        messages.append(ChatMessage(text: trimmed, isUser: true))
        isLoading = true
        errorMessage = nil

        if isPhoneReachable {
            sendViaPhone(trimmed)
        } else if hasAPIConfig {
            sendDirectly(trimmed)
        } else {
            errorMessage = "Open MLAIX on iPhone or configure API settings."
            isLoading = false
        }
    }

    /// Relay the question to the paired iPhone via WatchConnectivity.
    private func sendViaPhone(_ text: String) {
        #if os(watchOS)
        WCSession.default.sendMessage(
            ["question": text],
            replyHandler: { reply in
                Task { @MainActor in
                    if let answer = reply["reply"] as? String {
                        self.receiveReply(answer)
                    }
                    self.isLoading = false
                }
            },
            errorHandler: { error in
                Task { @MainActor in
                    // Fallback to direct API if phone relay fails
                    if self.hasAPIConfig {
                        self.sendDirectly(text)
                    } else {
                        self.errorMessage = error.localizedDescription
                        self.isLoading = false
                    }
                }
            }
        )
        #else
        // Not on watchOS — use direct API
        sendDirectly(text)
        #endif
    }

    /// Perform a direct OpenAI-compatible chat completion.
    private func sendDirectly(_ text: String) {
        Task {
            do {
                let reply = try await performChatRequest(userMessage: text)
                messages.append(ChatMessage(text: reply, isUser: false))
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func performChatRequest(userMessage: String) async throws -> String {
        guard let baseURL = URL(string: apiBaseURL), !apiKey.isEmpty else {
            throw URLError(.badURL)
        }

        let endpoint = baseURL.appendingPathComponent("chat/completions")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        // Keep context small on watch — last 6 messages
        let contextMessages = messages.suffix(6).map { msg -> [String: String] in
            ["role": msg.isUser ? "user" : "assistant", "content": msg.text]
        } + [["role": "user", "content": userMessage]]

        let body: [String: Any] = [
            "model": model,
            "messages": contextMessages,
            "max_tokens": 256,
            "temperature": 0.7
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw URLError(.cannotParseResponse)
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Called when a reply arrives from the phone or externally.
    func receiveReply(_ text: String) {
        messages.append(ChatMessage(text: text, isUser: false))
        isLoading = false
    }

    func clearChat() {
        messages.removeAll()
        errorMessage = nil
    }
}

// MARK: - Content View

struct watchOSContentView: View {
    @Environment(watchOSChatState.self) private var chatState

    var body: some View {
        NavigationStack {
            watchOSChatView()
                .navigationTitle("MLAIX")
                #if os(watchOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
        }
    }
}

// MARK: - Chat View

struct watchOSChatView: View {
    @Environment(watchOSChatState.self) private var chatState
    @State private var inputText: String = ""
    @State private var showSettings: Bool = false

    var body: some View {
        ScrollViewReader { proxy in
            List {
                if chatState.messages.isEmpty {
                    emptyState
                        .listRowBackground(Color.clear)
                }

                ForEach(chatState.messages) { message in
                    watchOSMessageRow(message: message)
                        .listRowInsets(EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4))
                        .id(message.id)
                }

                if chatState.isLoading {
                    HStack(spacing: 6) {
                        ProgressView()
                        Text("...")
                            .foregroundStyle(.secondary)
                    }
                    .id("loading")
                    .listRowBackground(Color.clear)
                }
            }
            .onChange(of: chatState.messages.count) { _, _ in
                withAnimation {
                    if let lastId = chatState.messages.last?.id {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            inputBar
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Clear") { chatState.clearChat() }
                    Button("Settings") { showSettings = true }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.caption)
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            watchOSSettingsView()
                .environment(chatState)
        }
    }

    private var inputBar: some View {
        HStack(spacing: 6) {
            TextField("Ask...", text: $inputText)
                .textFieldStyle(.plain)
                .lineLimit(1)
                .onSubmit { sendMessage() }

            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.tint)
            }
            .buttonStyle(.plain)
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || chatState.isLoading)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "brain.head.profile")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("MLAIX")
                .font(.headline)
            Text("Ask me anything")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 20)
    }

    private func sendMessage() {
        let text = inputText
        inputText = ""
        chatState.send(text)
    }
}

// MARK: - Message Row

struct watchOSMessageRow: View {
    let message: watchOSChatState.ChatMessage

    var body: some View {
        HStack {
            if message.isUser { Spacer(minLength: 20) }

            Text(message.text)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(message.isUser ? Color.accentColor.opacity(0.3) : Color.secondary.opacity(0.15))
                )

            if !message.isUser { Spacer(minLength: 20) }
        }
    }
}

// MARK: - Settings View

struct watchOSSettingsView: View {
    @Environment(watchOSChatState.self) private var chatState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var state = chatState

        NavigationStack {
            Form {
                Section("API") {
                    TextField("Base URL", text: $state.apiBaseURL)
                        #if os(iOS) || os(watchOS)
                        .textContentType(.URL)
                        #endif
                        .autocorrectionDisabled()
                    SecureField("API Key", text: $state.apiKey)
                    TextField("Model", text: $state.model)
                        .autocorrectionDisabled()
                }
                Section {
                    Button("Done") { dismiss() }
                }
            }
            .navigationTitle("Settings")
            #if os(watchOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }
}
