//
//  SharedConversation.swift
//  MLAIXShared
//

import Foundation
import SwiftData

/// Cross-platform conversation model using SwiftData.
@Model
public final class SharedConversation {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \SharedChatMessage.conversation)
    public var messages: [SharedChatMessage] = []

    public init(title: String = "New Chat", id: UUID = UUID()) {
        self.id = id
        self.title = title
        self.createdAt = Date()
    }
}
