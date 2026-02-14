//
//  MemoryModel.swift
//  MLAIXShared
//

import Foundation
import SwiftData

/// SwiftData model that mirrors the macOS `Memory` Codable struct.
/// Stores a single recalled "memory" extracted from a conversation message.
@Model
public final class MemoryModel {
    @Attribute(.unique) public var id: UUID

    /// The UUID of the message from which this memory was derived.
    public var messageId: UUID

    /// The text content of the memory.
    public var text: String

    /// The date on which the memory was created.
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        messageId: UUID,
        text: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.messageId = messageId
        self.text = text
        self.createdAt = createdAt
    }
}
