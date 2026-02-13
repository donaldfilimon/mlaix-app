//
//  InferenceRecordModel.swift
//  MLAIXShared
//

import Foundation
import SwiftData

/// SwiftData model that mirrors the macOS `InferenceRecord` Codable struct.
/// Captures telemetry for a single inference request (chat or completion).
@Model
public final class InferenceRecordModel {
    @Attribute(.unique) public var id: UUID

    /// The name of the model used for inference.
    public var name: String

    /// The usage type raw value ("completions" or "chatCompletions"),
    /// matching `InferenceRecord.UsageType.rawValue`.
    public var type: String

    /// Number of input (prompt) tokens.
    public var inputTokens: Int

    /// Number of output (generated) tokens.
    public var outputTokens: Int

    /// When the inference request started.
    public var startTime: Date

    /// When the inference request ended.
    public var endTime: Date

    /// Whether a remote server was used for this inference.
    public var usedRemoteServer: Bool

    // MARK: - Computed properties

    /// Total tokens processed (input + output).
    public var totalTokens: Int {
        inputTokens + outputTokens
    }

    /// Wall-clock duration in seconds.
    public var duration: Float {
        Float(endTime.timeIntervalSince(startTime))
    }

    /// Output tokens per second. Returns 0 if duration is non-positive.
    public var tokensPerSecond: Double {
        let elapsed = endTime.timeIntervalSince(startTime)
        guard elapsed > 0 else { return 0 }
        return Double(outputTokens) / elapsed
    }

    // MARK: - Initialiser

    public init(
        id: UUID = UUID(),
        name: String,
        type: String,
        inputTokens: Int,
        outputTokens: Int,
        startTime: Date,
        endTime: Date = .now,
        usedRemoteServer: Bool = false
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.startTime = startTime
        self.endTime = endTime
        self.usedRemoteServer = usedRemoteServer
    }
}
