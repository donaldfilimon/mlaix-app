//
//  CommandModel.swift
//  MLAIXShared
//

import Foundation
import SwiftData

/// SwiftData model that mirrors the macOS `Command` Codable struct.
/// Represents a reusable user-defined prompt command (e.g. "Correct Grammar").
@Model
public final class CommandModel {
    @Attribute(.unique) public var id: UUID

    /// The display name of the command.
    public var name: String

    /// The prompt text sent to the model when this command is invoked.
    public var prompt: String

    /// An SF Symbol name used as the command's icon.
    public var symbolName: String

    public init(
        id: UUID = UUID(),
        name: String,
        prompt: String,
        symbolName: String = "text.bubble"
    ) {
        self.id = id
        self.name = name
        self.prompt = prompt
        self.symbolName = symbolName
    }
}
