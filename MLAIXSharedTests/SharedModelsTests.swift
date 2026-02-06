//
//  SharedModelsTests.swift
//  MLAIXSharedTests
//

import Foundation
import SwiftData
import Testing
@testable import MLAIXShared

@MainActor
struct SharedModelsTests {

    @Test func testSharedChatMessageInit() async throws {
        let msg = SharedChatMessage(text: "Hello", isUser: true)
        #expect(msg.text == "Hello")
        #expect(msg.isUser)
        #expect(msg.id != UUID())
    }

    @Test func testSharedConversationInit() async throws {
        let conv = SharedConversation(title: "Test")
        #expect(conv.title == "Test")
        #expect(conv.messages.isEmpty)
    }
}
