//
//  iOSChatStateTests.swift
//  MLAIXiOSTests
//

import Foundation
import Testing
@testable import MLAIXiOS

@MainActor
struct iOSChatStateTests {

    @Test func testSendRequiresNonEmptyInput() async {
        let state = iOSChatState()
        state.inputText = "   "
        state.send()
        #expect(state.messages.isEmpty)
        #expect(state.inputText == "   ")
    }

    @Test func testSendAppendsUserMessage() async {
        let state = iOSChatState()
        state.inputText = "Hello"
        state.send()
        #expect(state.messages.count == 1)
        #expect(state.messages[0].isUser)
        #expect(state.messages[0].text == "Hello")
        #expect(state.inputText.isEmpty)
    }

    @Test func testSendClearsInput() async {
        let state = iOSChatState()
        state.inputText = "Test"
        state.send()
        #expect(state.inputText.isEmpty)
    }

    @Test func testiOSMessageIdentifiable() async {
        let msg = iOSChatState.iOSMessage(text: "Hi", isUser: true)
        #expect(msg.id != UUID())
        #expect(msg.text == "Hi")
        #expect(msg.isUser)
    }

    @Test func testRetryDoesNothingWhenNoLastMessage() async {
        let state = iOSChatState()
        state.retryLastMessage()
        #expect(state.messages.isEmpty)
        #expect(!state.isGenerating)
    }

    @Test func testStartNewConversationClearsMessages() async {
        let state = iOSChatState()
        state.inputText = "Hello"
        state.send()
        #expect(state.messages.count == 1)
        state.startNewConversation()
        #expect(state.messages.isEmpty)
        #expect(state.inputText.isEmpty)
    }

    // MARK: - handleIncomingURL

    @Test func testHandleIncomingURLNewChatClearsAndStartsFresh() async {
        let state = iOSChatState()
        state.inputText = "Existing"
        state.messages.append(.init(text: "Hi", isUser: true))
        guard let url = URL(string: "mlaix://new-chat") else { return }
        state.handleIncomingURL(url)
        #expect(state.messages.isEmpty)
        #expect(state.inputText.isEmpty)
    }

    @Test func testHandleIncomingURLAskSetsPrompt() async {
        let state = iOSChatState()
        guard let url = URL(string: "mlaix://ask?prompt=Hello%20World") else { return }
        state.handleIncomingURL(url)
        #expect(state.inputText == "Hello World")
    }

    @Test func testHandleIncomingURLAskStartsNewChat() async {
        let state = iOSChatState()
        state.messages.append(.init(text: "Old", isUser: true))
        guard let url = URL(string: "mlaix://ask?prompt=New") else { return }
        state.handleIncomingURL(url)
        #expect(state.messages.isEmpty)
        #expect(state.inputText == "New")
    }

    @Test func testHandleIncomingURLIgnoresNonMlaixScheme() async {
        let state = iOSChatState()
        state.inputText = "Keep"
        guard let url = URL(string: "https://example.com") else { return }
        state.handleIncomingURL(url)
        #expect(state.inputText == "Keep")
    }

    @Test func testHandleIncomingURLIgnoresUnknownHost() async {
        let state = iOSChatState()
        state.inputText = "Keep"
        guard let url = URL(string: "mlaix://other") else { return }
        state.handleIncomingURL(url)
        #expect(state.inputText == "Keep")
    }
}
