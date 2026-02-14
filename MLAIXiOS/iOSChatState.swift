//
//  iOSChatState.swift
//  MLAIX iOS / iPadOS
//

import Foundation
import SwiftData
import SwiftUI
import MLAIXShared
#if canImport(UIKit)
import UIKit
#endif

// MARK: - iOS Data Models

struct iOSConversation: Identifiable, Codable {
    let id: UUID
    var title: String
    var messages: [iOSMessage]
    var lastUpdated: Date

    init(id: UUID = UUID(), title: String = "New Chat", messages: [iOSMessage] = [], lastUpdated: Date = .now) {
        self.id = id
        self.title = title
        self.messages = messages
        self.lastUpdated = lastUpdated
    }
}

struct iOSMessage: Identifiable, Codable {
    let id: UUID
    var text: String
    let isUser: Bool
    let timestamp: Date

    init(id: UUID = UUID(), text: String, isUser: Bool, timestamp: Date = .now) {
        self.id = id
        self.text = text
        self.isUser = isUser
        self.timestamp = timestamp
    }
}

// MARK: - Chat State

/// Chat state for iOS/iPadOS (remote API only).
/// Uses @Observable (Observation framework) and persists conversations to JSON on disk.
@MainActor @Observable
final class iOSChatState {

    // MARK: Published State

    var conversations: [iOSConversation] = []
    var selectedConversationId: UUID?
    var inputText: String = ""
    var isGenerating: Bool = false
    var errorMessage: String?

    // MARK: Computed

    var currentConversation: iOSConversation? {
        guard let id = selectedConversationId else { return nil }
        return conversations.first { $0.id == id }
    }

    var messages: [iOSMessage] {
        currentConversation?.messages ?? []
    }

    // MARK: Private

    private var lastUserMessage: String?
    private var streamingTask: Task<Void, Never>?

    // MARK: Init

    /// ModelContext parameter kept for backward compatibility but no longer used for persistence.
    /// Conversations are now persisted as JSON in the app's documents directory.
    init(modelContext: ModelContext? = nil) {
        loadConversations()
        // Select most recent conversation or create one
        if conversations.isEmpty {
            let conv = iOSConversation()
            conversations.append(conv)
            selectedConversationId = conv.id
            saveConversations()
        } else {
            selectedConversationId = conversations.first?.id
        }
    }

    /// Convenience init for previews / testing.
    init() {
        loadConversations()
        if conversations.isEmpty {
            let conv = iOSConversation()
            conversations.append(conv)
            selectedConversationId = conv.id
            saveConversations()
        } else {
            selectedConversationId = conversations.first?.id
        }
    }

    // MARK: - Persistence (JSON file)

    private static var conversationsFileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("ios_conversations.json")
    }

    private func loadConversations() {
        let url = Self.conversationsFileURL
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([iOSConversation].self, from: data)
            conversations = decoded.sorted { $0.lastUpdated > $1.lastUpdated }
        } catch {
            // If decode fails, start fresh
            conversations = []
        }
    }

    private func saveConversations() {
        let url = Self.conversationsFileURL
        do {
            let data = try JSONEncoder().encode(conversations)
            try data.write(to: url, options: .atomic)
        } catch {
            // Silent fail; chat still works
        }
    }

    // MARK: - Conversation Management

    func selectConversation(_ id: UUID) {
        guard conversations.contains(where: { $0.id == id }) else { return }
        selectedConversationId = id
    }

    func deleteConversation(_ id: UUID) {
        conversations.removeAll { $0.id == id }
        if selectedConversationId == id {
            selectedConversationId = conversations.first?.id
        }
        if conversations.isEmpty {
            startNewConversation()
        }
        saveConversations()
    }

    func startNewConversation() {
        let conv = iOSConversation()
        conversations.insert(conv, at: 0)
        selectedConversationId = conv.id
        inputText = ""
        lastUserMessage = nil
        errorMessage = nil
        saveConversations()
    }

    /// Legacy method kept for backward compat — now a no-op (conversations load in init).
    func loadConversation() {}

    // MARK: - URL Handling

    func handleIncomingURL(_ url: URL) {
        guard url.scheme == "mlaix" else { return }
        switch url.host {
        case "new-chat":
            startNewConversation()
        case "ask":
            startNewConversation()
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let prompt = components.queryItems?.first(where: { $0.name == "prompt" })?.value?.removingPercentEncoding,
               !prompt.isEmpty {
                inputText = prompt
            }
        default:
            break
        }
    }

    // MARK: - Send (Streaming + Multi-Turn)

    func send() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isGenerating else { return }

        inputText = ""
        lastUserMessage = text

        // Ensure we have a selected conversation
        if selectedConversationId == nil {
            startNewConversation()
        }

        // Append user message
        let userMsg = iOSMessage(text: text, isUser: true)
        appendMessage(userMsg)

        // Auto-title: use first user message as title if still "New Chat"
        if let idx = conversationIndex, conversations[idx].title == "New Chat" {
            let titlePreview = String(text.prefix(40))
            conversations[idx].title = titlePreview + (text.count > 40 ? "..." : "")
        }

        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif

        isGenerating = true
        errorMessage = nil
        saveConversations()

        streamingTask = Task {
            do {
                try await performStreamingCompletion()
            } catch is CancellationError {
                isGenerating = false
            } catch {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                isGenerating = false
                // Remove the user message on error
                removeLastMessage(matching: userMsg.id)
                saveConversations()
            }
        }
    }

    func retryLastMessage() {
        guard let text = lastUserMessage, !text.isEmpty, !isGenerating else { return }
        inputText = text
        send()
    }

    // MARK: - Streaming Completion (SSE)

    private func performStreamingCompletion() async throws {
        let config = (
            baseURL: SharedAPIConfig.shared.apiBaseURL,
            apiKey: SharedAPIConfig.shared.apiKey,
            model: SharedAPIConfig.shared.model
        )
        guard let baseURL = config.baseURL else {
            throw SharedChatError.apiNotConfigured
        }
        guard let apiKey = config.apiKey, !apiKey.isEmpty else {
            throw SharedChatError.apiKeyMissing
        }
        let model = config.model ?? "gpt-4o-mini"

        var base = baseURL.absoluteString
        while base.hasSuffix("/") { base = String(base.dropLast()) }
        guard let normalizedBase = URL(string: base.hasPrefix("http") ? base : "https://\(base)") else {
            throw SharedChatError.invalidURL(base)
        }
        let url = normalizedBase.appendingPathComponent("chat/completions")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 120
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Build multi-turn messages array from full conversation history
        let conversationMessages = buildMessagesPayload()

        let body: [String: Any] = [
            "model": model,
            "messages": conversationMessages,
            "stream": true
        ]
        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else {
            throw SharedChatError.encodingFailed
        }
        request.httpBody = bodyData

        // Use URLSession.shared.bytes for streaming
        let (bytes, response): (URLSession.AsyncBytes, URLResponse)
        do {
            (bytes, response) = try await URLSession.shared.bytes(for: request)
        } catch {
            throw SharedChatError.networkError(underlying: error.localizedDescription)
        }
        guard let http = response as? HTTPURLResponse else {
            throw SharedChatError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            // Collect error body
            var errorData = Data()
            for try await byte in bytes {
                errorData.append(byte)
                if errorData.count > 1024 { break }
            }
            let bodyPreview = String(data: errorData, encoding: .utf8)?.prefix(200) ?? ""
            throw SharedChatError.apiError(statusCode: http.statusCode, bodyPreview: String(bodyPreview))
        }

        // Create a placeholder assistant message for streaming
        let assistantMsg = iOSMessage(text: "", isUser: false)
        appendMessage(assistantMsg)

        var accumulatedText = ""

        // Parse SSE stream
        for try await line in bytes.lines {
            try Task.checkCancellation()

            // SSE lines prefixed with "data: "
            guard line.hasPrefix("data: ") else { continue }
            let payload = String(line.dropFirst(6))

            // Stream end signal
            if payload.trimmingCharacters(in: .whitespaces) == "[DONE]" {
                break
            }

            // Parse JSON chunk
            guard let chunkData = payload.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: chunkData) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let delta = firstChoice["delta"] as? [String: Any],
                  let content = delta["content"] as? String else {
                continue
            }

            accumulatedText += content

            // Update the assistant message in place
            updateMessageText(id: assistantMsg.id, text: accumulatedText)
        }

        isGenerating = false
        saveConversations()
    }

    // MARK: - Multi-Turn Messages Payload

    private func buildMessagesPayload() -> [[String: String]] {
        guard let conv = currentConversation else { return [] }
        return conv.messages.map { msg in
            [
                "role": msg.isUser ? "user" : "assistant",
                "content": msg.text
            ]
        }
    }

    // MARK: - Helpers

    private var conversationIndex: Int? {
        guard let id = selectedConversationId else { return nil }
        return conversations.firstIndex { $0.id == id }
    }

    private func appendMessage(_ message: iOSMessage) {
        guard let idx = conversationIndex else { return }
        conversations[idx].messages.append(message)
        conversations[idx].lastUpdated = .now
    }

    private func updateMessageText(id: UUID, text: String) {
        guard let convIdx = conversationIndex else { return }
        guard let msgIdx = conversations[convIdx].messages.firstIndex(where: { $0.id == id }) else { return }
        conversations[convIdx].messages[msgIdx].text = text
    }

    private func removeLastMessage(matching id: UUID) {
        guard let idx = conversationIndex else { return }
        conversations[idx].messages.removeAll { $0.id == id }
    }
}
