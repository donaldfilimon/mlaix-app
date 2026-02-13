//
//  ServerArgumentModel.swift
//  MLAIXShared
//

import Foundation
import SwiftData

/// SwiftData model that mirrors the macOS `ServerArgument` Codable struct.
/// Represents a single CLI flag/value pair passed to `llama-server`.
@Model
public final class ServerArgumentModel {
    @Attribute(.unique) public var id: UUID

    /// The CLI flag (e.g. "--flash-attn", "--top-k").
    public var flag: String

    /// The value associated with the flag (empty string for boolean flags).
    public var value: String

    /// Whether this argument is currently active and should be included in the server launch.
    public var isActive: Bool

    public init(
        id: UUID = UUID(),
        flag: String,
        value: String = "",
        isActive: Bool = false
    ) {
        self.id = id
        self.flag = flag
        self.value = value
        self.isActive = isActive
    }
}
