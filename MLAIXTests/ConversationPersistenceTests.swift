//
//  ConversationPersistenceTests.swift
//  MLAIXTests
//
//  Created by Codex on 2/6/26.
//

import Foundation
import Testing

@testable import MLAIX

@Suite(.serialized)
struct ConversationPersistenceTests {

    @Test @MainActor
    func conversationTitleUpdatesOnFirstMessage() {
        var conversation = Conversation(title: "New Conversation")
        let message = Message(text: "Hello world", sender: .user)

        let didAdd = conversation.addMessage(message)

        #expect(didAdd)
        #expect(conversation.title == "Hello world")
    }

    @Test @MainActor
    func conversationManagerDebouncedSaveWritesToDisk() async throws {
        let containerUrl = try TestUtilities.makeTempContainerUrl()
        defer { try? FileManager.default.removeItem(at: containerUrl) }
        let manager = ConversationManager(containerUrl: containerUrl)

        await TestUtilities.waitForLoaded(manager)

        manager.newConversation()

        try await TestUtilities.wait(TestUtilities.saveDebounceWait)

        let rawData = try Data(contentsOf: manager.datastoreUrl)
        let decoded = try JSONDecoder().decode([Conversation].self, from: rawData)

        #expect(!decoded.isEmpty, "Debounced save should have written at least one conversation to disk")
    }

    @Test @MainActor
    func saveNowFlushesImmediately() async throws {
        let containerUrl = try TestUtilities.makeTempContainerUrl()
        defer { try? FileManager.default.removeItem(at: containerUrl) }
        let manager = ConversationManager(containerUrl: containerUrl)

        await TestUtilities.waitForLoaded(manager)

        manager.newConversation()
        manager.saveNow()

        let rawData = try Data(contentsOf: manager.datastoreUrl)
        let decoded = try JSONDecoder().decode([Conversation].self, from: rawData)

        #expect(!decoded.isEmpty, "saveNow() should flush conversations to disk immediately")
    }

    @Test @MainActor
    func multipleRapidSavesCoalesceIntoOne() async throws {
        let containerUrl = try TestUtilities.makeTempContainerUrl()
        defer { try? FileManager.default.removeItem(at: containerUrl) }
        let manager = ConversationManager(containerUrl: containerUrl)

        await TestUtilities.waitForLoaded(manager)

        for _ in 0..<5 {
            manager.newConversation()
        }

        try await TestUtilities.wait(TestUtilities.saveDebounceWait)

        let rawData = try Data(contentsOf: manager.datastoreUrl)
        let decoded = try JSONDecoder().decode([Conversation].self, from: rawData)

        #expect(decoded.count == 6, "Expected 1 from initial load plus 5 new conversations (got \(decoded.count))")
    }

    @Test @MainActor
    func conversationTitleNotOverwrittenBySecondMessage() {
        var conversation = Conversation(title: "New Conversation")
        let first = Message(text: "First message", sender: .user)
        let second = Message(text: "Second message", sender: .assistant)

        _ = conversation.addMessage(first)
        _ = conversation.addMessage(second)

        #expect(conversation.title == "First message")
    }
}
