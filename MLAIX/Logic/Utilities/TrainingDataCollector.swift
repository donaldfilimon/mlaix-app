//
//  TrainingDataCollector.swift
//  MLAI
//
//  Collects prompt→label pairs for self-learning and CoreML classifier training.
//

import Foundation
import OSLog

/// Collects user feedback and conversation-derived data for model training.
@MainActor
public enum TrainingDataCollector {

    private static let logger = Logger(
        subsystem: Bundle.main.logSubsystem,
        category: String(describing: TrainingDataCollector.self)
    )

    /// CSV file for collected prompt classifier training data.
    public static var trainingDataUrl: URL {
        Settings.containerUrl
            .appendingPathComponent("CoreML", isDirectory: true)
            .appendingPathComponent("prompt_classifier_training.csv")
    }

    /// Records a user-confirmed prompt→result-type pair (e.g. from the Text/Image dichotomy).
    /// Appends to the training CSV for later retraining.
    public static func recordUserChoice(prompt: String, label: String) {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !label.isEmpty else { return }

        let escapedText = trimmed
            .replacingOccurrences(of: "\"", with: "\"\"")
            .replacingOccurrences(of: "\n", with: " ")
        let csvLine = "\"\(escapedText)\",\"\(label)\"\n"

        let dirUrl = trainingDataUrl.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: dirUrl.path) {
            try? FileManager.default.createDirectory(at: dirUrl, withIntermediateDirectories: true)
        }

        let needsHeader = !FileManager.default.fileExists(atPath: trainingDataUrl.path)
        let content = needsHeader ? "text,label\n" + csvLine : csvLine

        if let data = content.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: trainingDataUrl.path) {
                if let handle = try? FileHandle(forWritingTo: trainingDataUrl) {
                    handle.seekToEndOfFile()
                    handle.write(data)
                    try? handle.close()
                }
            } else {
                try? data.write(to: trainingDataUrl)
            }
            Self.logger.debug("Recorded training sample: \(label, privacy: .public)")
        }
    }

    /// Exports conversation-derived training data from conversations.
    /// User prompts are labeled by the assistant's response type (text vs image).
    public static func exportFromConversations(
        _ conversations: [Conversation]
    ) -> [(text: String, label: String)] {
        var samples: [(String, String)] = []
        for conversation in conversations {
            let messages = conversation.messages
            for i in messages.indices {
                let msg = messages[i]
                guard msg.getSender() == .user, !msg.text.isEmpty else { continue }
                let nextIdx = messages.index(after: i)
                guard nextIdx < messages.endIndex else { continue }
                let nextMsg = messages[nextIdx]
                guard nextMsg.getSender() == .assistant else { continue }

                let label: String
                if nextMsg.imageUrl != nil {
                    label = PromptAnalyzer.ResultType.image.rawValue
                } else {
                    label = PromptAnalyzer.ResultType.text.rawValue
                }
                samples.append((msg.text.trimmingCharacters(in: .whitespacesAndNewlines), label))
            }
        }
        return samples
    }

    /// Appends exported conversation samples to the training CSV.
    public static func appendExportedSamples(_ samples: [(text: String, label: String)]) {
        guard !samples.isEmpty else { return }

        let dirUrl = trainingDataUrl.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: dirUrl.path) {
            try? FileManager.default.createDirectory(at: dirUrl, withIntermediateDirectories: true)
        }

        let lines = samples.map { text, label in
            let escaped = text
                .replacingOccurrences(of: "\"", with: "\"\"")
                .replacingOccurrences(of: "\n", with: " ")
            return "\"\(escaped)\",\"\(label)\""
        }
        let csvContent = lines.joined(separator: "\n") + "\n"

        let needsHeader = !FileManager.default.fileExists(atPath: trainingDataUrl.path)
        let content = needsHeader ? "text,label\n" + csvContent : csvContent

        if let data = content.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: trainingDataUrl.path), !needsHeader {
                if let handle = try? FileHandle(forWritingTo: trainingDataUrl) {
                    handle.seekToEndOfFile()
                    handle.write(data)
                    try? handle.close()
                }
            } else {
                try? data.write(to: trainingDataUrl)
            }
            Self.logger.info("Appended \(samples.count) training samples from conversations")
        }
    }

    /// Returns the number of samples in the collected training file.
    public static var collectedSampleCount: Int {
        guard let content = try? String(contentsOf: trainingDataUrl, encoding: .utf8) else {
            return 0
        }
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        return max(0, lines.count - 1)  // subtract header
    }
}
