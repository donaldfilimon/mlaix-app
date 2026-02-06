//
//  ConversationPersistenceTests.swift
//  SidekickTests
//
//  Created by Codex on 2/6/26.
//

import Foundation
import Testing
@testable import MLAI

struct ConversationPersistenceTests {

    @MainActor
    private func makeTempContainerUrl() throws -> URL {
        let base = FileManager.default.temporaryDirectory
            .appendingPathComponent("MLAI-Tests")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(
            at: base,
            withIntermediateDirectories: true
        )
        return base
    }

    @MainActor
    private func waitForLoaded(_ manager: ConversationManager) async {
        while !manager.isLoaded {
            try? await Task.sleep(for: .milliseconds(50))
        }
    }

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
        let containerUrl = try makeTempContainerUrl()
        let manager = ConversationManager(containerUrl: containerUrl)

        await waitForLoaded(manager)

        manager.newConversation()

        try await Task.sleep(for: .milliseconds(700))

        let rawData = try Data(contentsOf: manager.datastoreUrl)
        let decoded = try JSONDecoder().decode([Conversation].self, from: rawData)

        #expect(!decoded.isEmpty)
    }

    @Test @MainActor
    func saveNowFlushesImmediately() async throws {
        let containerUrl = try makeTempContainerUrl()
        let manager = ConversationManager(containerUrl: containerUrl)

        await waitForLoaded(manager)

        manager.newConversation()
        // saveNow bypasses the 350ms debounce
        manager.saveNow()

        let rawData = try Data(contentsOf: manager.datastoreUrl)
        let decoded = try JSONDecoder().decode([Conversation].self, from: rawData)

        #expect(!decoded.isEmpty)
    }

    @Test @MainActor
    func multipleRapidSavesCoalesceIntoOne() async throws {
        let containerUrl = try makeTempContainerUrl()
        let manager = ConversationManager(containerUrl: containerUrl)

        await waitForLoaded(manager)

        // Create 5 conversations rapidly — each triggers save() via didSet
        for _ in 0..<5 {
            manager.newConversation()
        }

        // Wait for debounce to flush
        try await Task.sleep(for: .milliseconds(700))

        let rawData = try Data(contentsOf: manager.datastoreUrl)
        let decoded = try JSONDecoder().decode([Conversation].self, from: rawData)

        // All 5 conversations should be persisted
        #expect(decoded.count == 5)
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
