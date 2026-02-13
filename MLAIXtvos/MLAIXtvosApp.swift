//
//  MLAIXtvosApp.swift
//  MLAIX tvOS
//

import SwiftUI
import MLAIXShared

// MARK: - App Entry Point

@main
struct MLAIXtvosApp: App {
    @State private var chatState = tvOSChatState()

    var body: some Scene {
        WindowGroup {
            tvOSContentView()
                .environment(chatState)
        }
    }
}

// MARK: - Chat State

/// Observable chat state for tvOS — lightweight wrapper around SharedAPIConfig + network calls.
@Observable
@MainActor
final class tvOSChatState {

    struct ChatMessage: Identifiable {
        let id = UUID()
        let text: String
        let isUser: Bool
        let date = Date()
    }

    var messages: [ChatMessage] = []
    var inputText: String = ""
    var isLoading: Bool = false
    var errorMessage: String?

    private var config: SharedAPIConfig { SharedAPIConfig.shared }

    var isConfigured: Bool { config.hasConfiguredAPI }

    // MARK: - API Configuration

    var apiBaseURL: String {
        get { config.apiBaseURL?.absoluteString ?? "" }
        set { config.apiBaseURL = URL(string: newValue) }
    }

    var apiKey: String {
        get { config.apiKey ?? "" }
        set { config.apiKey = newValue }
    }

    var model: String {
        get { config.model ?? "gpt-4o-mini" }
        set { config.model = newValue }
    }

    // MARK: - Send Message

    func send() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return }

        messages.append(ChatMessage(text: text, isUser: true))
        inputText = ""
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let reply = try await performChatRequest(userMessage: text)
                messages.append(ChatMessage(text: reply, isUser: false))
            } catch {
                errorMessage = error.localizedDescription
                messages.append(ChatMessage(text: "Error: \(error.localizedDescription)", isUser: false))
            }
            isLoading = false
        }
    }

    /// Perform an OpenAI-compatible chat completion request.
    private func performChatRequest(userMessage: String) async throws -> String {
        guard let baseURL = config.apiBaseURL,
              let apiKey = config.apiKey, !apiKey.isEmpty else {
            throw URLError(.badURL)
        }

        let endpoint = baseURL.appendingPathComponent("chat/completions")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // Build messages payload — include recent context (last 20 messages)
        let contextMessages = messages.suffix(20).map { msg -> [String: String] in
            ["role": msg.isUser ? "user" : "assistant", "content": msg.text]
        } + [["role": "user", "content": userMessage]]

        let body: [String: Any] = [
            "model": model,
            "messages": contextMessages,
            "max_tokens": 1024,
            "temperature": 0.7
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw URLError(.badServerResponse, userInfo: [
                NSLocalizedDescriptionKey: "Server returned status \(statusCode)"
            ])
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

    func clearChat() {
        messages.removeAll()
        errorMessage = nil
    }
}

// MARK: - Content View (Router)

struct tvOSContentView: View {
    @Environment(tvOSChatState.self) private var chatState

    var body: some View {
        Group {
            if chatState.isConfigured {
                tvOSChatView()
            } else {
                tvOSSetupView()
            }
        }
    }
}

// MARK: - Chat View

struct tvOSChatView: View {
    @Environment(tvOSChatState.self) private var chatState
    @FocusState private var isInputFocused: Bool

    var body: some View {
        @Bindable var state = chatState

        NavigationStack {
            VStack(spacing: 0) {
                // Messages list
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            if chatState.messages.isEmpty {
                                emptyState
                            }
                            ForEach(chatState.messages) { message in
                                tvOSMessageBubble(message: message)
                                    .id(message.id)
                            }
                            if chatState.isLoading {
                                HStack {
                                    ProgressView()
                                        .padding(.trailing, 8)
                                    Text("Thinking...")
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 40)
                                .id("loading")
                            }
                        }
                        .padding(.vertical, 24)
                    }
                    .onChange(of: chatState.messages.count) { _, _ in
                        withAnimation {
                            if let lastId = chatState.messages.last?.id {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            } else if chatState.isLoading {
                                proxy.scrollTo("loading", anchor: .bottom)
                            }
                        }
                    }
                }

                Divider()

                // Input area
                HStack(spacing: 16) {
                    TextField("Ask something...", text: $state.inputText)
                        .textFieldStyle(.plain)
                        .focused($isInputFocused)
                        .onSubmit {
                            chatState.send()
                        }

                    Button {
                        chatState.send()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                    }
                    .disabled(chatState.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || chatState.isLoading)
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 20)
            }
            .navigationTitle("MLAIX")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Clear Chat", role: .destructive) {
                            chatState.clearChat()
                        }
                        Button("Settings") {
                            // Navigate to setup — handled via state
                            chatState.apiBaseURL = ""
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .onAppear {
            isInputFocused = true
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("MLAIX")
                .font(.title)
            Text("Ask me anything using the remote or dictation.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }
}

// MARK: - Message Bubble

struct tvOSMessageBubble: View {
    let message: tvOSChatState.ChatMessage

    var body: some View {
        HStack {
            if message.isUser { Spacer(minLength: 100) }

            Text(message.text)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(message.isUser ? Color.accentColor.opacity(0.3) : Color.secondary.opacity(0.15))
                )
                .foregroundStyle(message.isUser ? .primary : .primary)

            if !message.isUser { Spacer(minLength: 100) }
        }
        .padding(.horizontal, 40)
        .focusable()
    }
}

// MARK: - Setup View

struct tvOSSetupView: View {
    @Environment(tvOSChatState.self) private var chatState
    @FocusState private var focusedField: SetupField?

    enum SetupField: Hashable {
        case baseURL, apiKey, model, save
    }

    var body: some View {
        @Bindable var state = chatState

        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        Text("MLAIX Setup")
                            .font(.title)
                        Text("Configure your API endpoint to get started.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)

                    // Form fields
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("API Base URL")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("https://api.openai.com/v1", text: $state.apiBaseURL)
                                .focused($focusedField, equals: .baseURL)
                                .textContentType(.URL)
                                .autocorrectionDisabled()
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("API Key")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            SecureField("sk-...", text: $state.apiKey)
                                .focused($focusedField, equals: .apiKey)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Model")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("gpt-4o-mini", text: $state.model)
                                .focused($focusedField, equals: .model)
                                .autocorrectionDisabled()
                        }
                    }
                    .padding(.horizontal, 60)

                    // Save button
                    Button {
                        focusedField = nil
                    } label: {
                        Text("Save & Start")
                            .font(.headline)
                            .frame(width: 300)
                    }
                    .focused($focusedField, equals: .save)
                    .disabled(!chatState.isConfigured)
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            focusedField = .baseURL
        }
    }
}
