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

/// Chat state for iOS/iPadOS (remote API only). Persists to SwiftData when context provided.
@MainActor
final class iOSChatState: ObservableObject {
    @Published var messages: [iOSMessage] = []
    @Published var inputText: String = ""
    @Published var isGenerating: Bool = false
    @Published var errorMessage: String?

    private var lastUserMessage: String?
    private var modelContext: ModelContext?
    private var currentConversation: SharedConversation?

    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }

    private func persist() {
        guard let ctx = modelContext else { return }
        do {
            try ctx.save()
        } catch {
            // Silent fail for persistence; chat still works
        }
    }

    func loadConversation() {
        guard let ctx = modelContext else { return }
        let descriptor = FetchDescriptor<SharedConversation>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        guard let conv = try? ctx.fetch(descriptor).first else { return }
        currentConversation = conv
        messages = conv.messages.map { iOSMessage(text: $0.text, isUser: $0.isUser, id: $0.id, date: $0.createdAt) }
    }

    func ensureConversation() {
        guard let ctx = modelContext, currentConversation == nil else { return }
        let conv = SharedConversation(title: "Chat")
        ctx.insert(conv)
        currentConversation = conv
        persist()
    }

    /// Start a new conversation; clears current messages and creates a fresh conversation.
    func startNewConversation() {
        currentConversation = nil
        messages = []
        inputText = ""
        lastUserMessage = nil
        errorMessage = nil
        ensureConversation()
    }

    /// Handle incoming URL from Shortcuts, Watch, or deep link (e.g. mlaix://new-chat, mlaix://ask?prompt=...).
    func handleIncomingURL(_ url: URL) {
        guard url.scheme == "mlaix" else { return }
        switch url.host {
        case "new-chat":
            startNewConversation()
        case "ask":
            startNewConversation()
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let prompt = components.queryItems?.first(where: { $0.name == "prompt" })?.value?.removingPercentEncoding, !prompt.isEmpty {
                inputText = prompt
            }
        default:
            break
        }
    }

    struct iOSMessage: Identifiable {
        let id: UUID
        let text: String
        let isUser: Bool
        let date: Date

        init(text: String, isUser: Bool, id: UUID = UUID(), date: Date = Date()) {
            self.id = id
            self.text = text
            self.isUser = isUser
            self.date = date
        }
    }

    func send() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isGenerating else { return }

        inputText = ""
        lastUserMessage = text
        ensureConversation()
        let userMsg = SharedChatMessage(text: text, isUser: true)
        userMsg.conversation = currentConversation
        modelContext?.insert(userMsg)
        currentConversation?.messages.append(userMsg)
        messages.append(.init(text: text, isUser: true, id: userMsg.id, date: userMsg.createdAt))
        persist()
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
        isGenerating = true
        errorMessage = nil

        Task {
            do {
                let response = try await performCompletion(prompt: text)
                await MainActor.run {
                    let assistantMsg = SharedChatMessage(text: response, isUser: false)
                    self.modelContext?.insert(assistantMsg)
                    self.currentConversation?.messages.append(assistantMsg)
                    self.messages.append(.init(text: response, isUser: false, id: assistantMsg.id, date: assistantMsg.createdAt))
                    self.isGenerating = false
                    self.persist()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                    self.isGenerating = false
                    self.messages.removeAll { $0.text == text && $0.isUser }
                    self.currentConversation?.messages.removeAll { $0.id == userMsg.id }
                    self.modelContext?.delete(userMsg)
                    self.persist()
                }
            }
        }
    }

    private func performCompletion(prompt: String) async throws -> String {
        let config = await MainActor.run {
            (baseURL: SharedAPIConfig.shared.apiBaseURL, apiKey: SharedAPIConfig.shared.apiKey, model: SharedAPIConfig.shared.model)
        }
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
        request.timeoutInterval = 60
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "stream": false
        ]
        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else {
            throw SharedChatError.encodingFailed
        }
        request.httpBody = bodyData

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw SharedChatError.networkError(underlying: error.localizedDescription)
        }
        guard let http = response as? HTTPURLResponse else {
            throw SharedChatError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let bodyPreview = String(data: data, encoding: .utf8)?.prefix(200) ?? ""
            throw SharedChatError.apiError(statusCode: http.statusCode, bodyPreview: String(bodyPreview))
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw SharedChatError.invalidResponse
        }
        return content
    }

    func retryLastMessage() {
        guard let text = lastUserMessage, !text.isEmpty, !isGenerating else { return }
        isGenerating = true
        errorMessage = nil
        Task {
            do {
                let response = try await performCompletion(prompt: text)
                await MainActor.run {
                    let assistantMsg = SharedChatMessage(text: response, isUser: false)
                    assistantMsg.conversation = self.currentConversation
                    self.modelContext?.insert(assistantMsg)
                    self.currentConversation?.messages.append(assistantMsg)
                    self.messages.append(.init(text: response, isUser: false, id: assistantMsg.id, date: assistantMsg.createdAt))
                    self.isGenerating = false
                    self.persist()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                    self.isGenerating = false
                }
            }
        }
    }
}
