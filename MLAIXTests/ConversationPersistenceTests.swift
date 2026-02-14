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

    @Test @MainActor
    func deleteConversationRemovesFromList() async throws {
        let containerUrl = try TestUtilities.makeTempContainerUrl()
        defer { try? FileManager.default.removeItem(at: containerUrl) }
        let manager = ConversationManager(containerUrl: containerUrl)
        await TestUtilities.waitForLoaded(manager)

        let initialCount = manager.conversations.count
        manager.newConversation()
        #expect(manager.conversations.count == initialCount + 1)

        let convToDelete = manager.conversations.last!
        manager.delete(convToDelete)
        #expect(manager.conversations.count == initialCount, "Conversation should be removed after deletion")
    }

    @Test @MainActor
    func reloadFromDiskPreservesData() async throws {
        let containerUrl = try TestUtilities.makeTempContainerUrl()
        defer { try? FileManager.default.removeItem(at: containerUrl) }

        // Create and save
        let manager1 = ConversationManager(containerUrl: containerUrl)
        await TestUtilities.waitForLoaded(manager1)
        manager1.newConversation()
        manager1.newConversation()
        manager1.saveNow()

        // Load fresh
        let manager2 = ConversationManager(containerUrl: containerUrl)
        await TestUtilities.waitForLoaded(manager2)

        #expect(manager2.conversations.count >= 2, "Reloaded manager should have at least 2 conversations (initial + 2 new)")
    }

    @Test @MainActor
    func messageOrderingPreserved() {
        var conversation = Conversation(title: "Test")
        let messages = (0..<10).map { i in
            Message(text: "Message \(i)", sender: i % 2 == 0 ? .user : .assistant)
        }
        for msg in messages {
            _ = conversation.addMessage(msg)
        }
        #expect(conversation.messages.count == 10, "All messages should be added")
        for (i, msg) in conversation.messages.enumerated() {
            #expect(msg.text == "Message \(i)", "Messages should be in insertion order")
        }
    }

    @Test @MainActor
    func conversationWithSpecialCharacters() async throws {
        let containerUrl = try TestUtilities.makeTempContainerUrl()
        defer { try? FileManager.default.removeItem(at: containerUrl) }
        let manager = ConversationManager(containerUrl: containerUrl)
        await TestUtilities.waitForLoaded(manager)

        manager.newConversation()
        let specialText = "Hello 🌍 \"quotes\" & <tags> 日本語 \n newline"
        let msg = Message(text: specialText, sender: .user)
        if var conv = manager.conversations.last {
            _ = conv.addMessage(msg)
            manager.update(conv)
        }
        manager.saveNow()

        // Reload and verify
        let manager2 = ConversationManager(containerUrl: containerUrl)
        await TestUtilities.waitForLoaded(manager2)
        let reloaded = manager2.conversations.last
        #expect(reloaded?.messages.last?.text == specialText, "Special characters should survive round-trip")
    }
}
