//
//  SharedChatMessage.swift
//  MLAIXShared
//

import Foundation
import SwiftData

/// Cross-platform chat message model using SwiftData.
@Model
public final class SharedChatMessage {
    @Attribute(.unique) public var id: UUID
    public var text: String
    public var isUser: Bool
    public var createdAt: Date
    public var conversation: SharedConversation?

    public init(text: String, isUser: Bool, id: UUID = UUID()) {
        self.id = id
        self.text = text
        self.isUser = isUser
        self.createdAt = Date()
    }
}
