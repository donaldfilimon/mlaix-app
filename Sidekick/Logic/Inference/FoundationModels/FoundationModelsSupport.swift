//
//  FoundationModelsSupport.swift
//  MLAI
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

enum FoundationModelsSupport {

    enum AvailabilityStatus: Equatable {
        case available
        case unavailable(String)
    }

    static var availabilityStatus: AvailabilityStatus {
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            let model = SystemLanguageModel.default
            switch model.availability {
                case .available:
                    return .available
                case .unavailable(let reason):
                    return .unavailable(String(describing: reason))
            }
        }
        #endif
        return .unavailable("Requires macOS 26 with Apple Intelligence enabled.")
    }

    static var isAvailable: Bool {
        if case .available = availabilityStatus {
            return true
        }
        return false
    }

    static var availabilityDescription: String {
        switch availabilityStatus {
            case .available:
                return "Available"
            case .unavailable(let reason):
                return "Unavailable: \(reason)"
        }
    }

}

#if canImport(FoundationModels)
@available(macOS 26.0, *)
@MainActor
final class FoundationModelsClient {

    static let shared = FoundationModelsClient()

    private var session: LanguageModelSession
    private var lastSystemPrompt: String

    init(systemPrompt: String = InferenceSettings.systemPrompt) {
        self.lastSystemPrompt = systemPrompt
        self.session = LanguageModelSession(instructions: systemPrompt)
    }

    func updateSystemPrompt(_ systemPrompt: String) {
        guard systemPrompt != lastSystemPrompt else { return }
        resetSession(systemPrompt: systemPrompt)
    }

    func resetSession(systemPrompt: String) {
        self.lastSystemPrompt = systemPrompt
        self.session = LanguageModelSession(instructions: systemPrompt)
    }

    func respond(to prompt: String) async throws -> String {
        let response = try await session.respond(to: prompt)
        return response.content
    }

}
#endif
