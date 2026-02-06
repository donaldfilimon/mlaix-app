//
//  TrainingDataCollectorTests.swift
//  MLAIXTests
//
//  Tests for TrainingDataCollector export logic and URL structure.
//

import Foundation
import Testing
@testable import MLAIX

struct TrainingDataCollectorTests {

    @Test @MainActor func testTrainingDataUrlEndsWithExpectedPath() {
        let url = TrainingDataCollector.trainingDataUrl
        #expect(url.lastPathComponent == "prompt_classifier_training.csv")
        #expect(url.pathComponents.contains("CoreML"))
    }

    @Test @MainActor func testExportFromConversationsExtractsUserAssistantTextPairs() {
        var conv = Conversation(title: "Text")
        _ = conv.addMessage(Message(text: "Draw a cat", sender: .user))
        _ = conv.addMessage(Message(text: "Here's a description", sender: .assistant))

        let samples = TrainingDataCollector.exportFromConversations([conv])

        #expect(samples.count == 1)
        #expect(samples[0].text == "Draw a cat")
        #expect(samples[0].label == "text-generation")
    }

    @Test @MainActor func testExportFromConversationsHandlesMultiplePairs() {
        var conv = Conversation(title: "Multi")
        _ = conv.addMessage(Message(text: "First", sender: .user))
        _ = conv.addMessage(Message(text: "Answer 1", sender: .assistant))
        _ = conv.addMessage(Message(text: "Second", sender: .user))
        _ = conv.addMessage(Message(text: "Answer 2", sender: .assistant))

        let samples = TrainingDataCollector.exportFromConversations([conv])
        #expect(samples.count == 2)
        #expect(samples[0].text == "First" && samples[0].label == "text-generation")
        #expect(samples[1].text == "Second" && samples[1].label == "text-generation")
    }

    @Test @MainActor func testExportFromConversationsSkipsIncompletePairs() {
        var conv = Conversation(title: "Incomplete")
        _ = conv.addMessage(Message(text: "Hello", sender: .user))
        // No assistant response

        let samples = TrainingDataCollector.exportFromConversations([conv])
        #expect(samples.isEmpty)
    }

    @Test @MainActor func testExportFromConversationsSkipsEmptyUserMessages() {
        var conv = Conversation(title: "Empty")
        _ = conv.addMessage(Message(text: "", sender: .user))
        _ = conv.addMessage(Message(text: "Hi", sender: .assistant))

        let samples = TrainingDataCollector.exportFromConversations([conv])
        #expect(samples.isEmpty)
    }
}
