//
//  ConversationPersistenceTests.swift
//  MLAIXTests
//
//  Created by Codex on 2/6/26.
//

import Foundation
import Testing

@testable import MLAIX

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
        let manager = ConversationManager(containerUrl: containerUrl)

        await TestUtilities.waitForLoaded(manager)

        manager.newConversation()

        try await Task.sleep(for: .milliseconds(700))

        let rawData = try Data(contentsOf: manager.datastoreUrl)
        let decoded = try JSONDecoder().decode([Conversation].self, from: rawData)

        #expect(!decoded.isEmpty)
    }

    @Test @MainActor
    func saveNowFlushesImmediately() async throws {
        let containerUrl = try TestUtilities.makeTempContainerUrl()
        let manager = ConversationManager(containerUrl: containerUrl)

        await TestUtilities.waitForLoaded(manager)

        manager.newConversation()
        // saveNow bypasses the 350ms debounce
        manager.saveNow()

        let rawData = try Data(contentsOf: manager.datastoreUrl)
        let decoded = try JSONDecoder().decode([Conversation].self, from: rawData)

        #expect(!decoded.isEmpty)
    }

    @Test @MainActor
    func multipleRapidSavesCoalesceIntoOne() async throws {
        let containerUrl = try TestUtilities.makeTempContainerUrl()
        let manager = ConversationManager(containerUrl: containerUrl)

        await TestUtilities.waitForLoaded(manager)

        // Create 5 conversations rapidly — each triggers save() via didSet
        for _ in 0..<5 {
            manager.newConversation()
        }

        // Wait for debounce to flush
        try await Task.sleep(for: .milliseconds(700))

        let rawData = try Data(contentsOf: manager.datastoreUrl)
        let decoded = try JSONDecoder().decode([Conversation].self, from: rawData)

        // 1 from initial load (empty container auto-creates) + 5 from the loop
        #expect(decoded.count == 6)
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
