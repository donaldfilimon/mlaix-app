//
//  MLXRunner.swift
//  MLAI
//
//  Created by Codex on 2/5/26.
//

import Foundation
import MLX
import MLXLLM
import MLXLMCommon
import OSLog

public enum MLXRunner {
    static let logger: Logger = .init(
        subsystem: Bundle.main.logSubsystem,
        category: String(describing: MLXRunner.self)
    )

    // MARK: - Types

    public struct Availability: Sendable {
        let pythonAvailable: Bool   // Kept for backward compat (always false)
        let mlxAvailable: Bool
        let mlxVersion: String?
        let nativeAvailable: Bool   // Native Swift MLX
    }

    public struct Message: Codable, Sendable {
        let role: String
        let content: String
    }

    public struct Request: Codable, Sendable {
        let modelPath: String
        let messages: [Message]
        let maxTokens: Int
        let temperature: Double
        let topP: Double

        enum CodingKeys: String, CodingKey {
            case modelPath = "model_path"
            case messages
            case maxTokens = "max_tokens"
            case temperature
            case topP = "top_p"
        }
    }

    public struct Response: Codable, Sendable {
        let text: String?
        let promptTokens: Int?
        let completionTokens: Int?
        let error: String?

        enum CodingKeys: String, CodingKey {
            case text
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case error
        }
    }

    public enum MLXError: LocalizedError {
        case pythonUnavailable
        case invalidResponse
        case generationFailed(String)
        case modelLoadFailed(String)

        public var errorDescription: String? {
            switch self {
            case .pythonUnavailable:
                return "Python is not available (native MLX is used instead)"
            case .invalidResponse:
                return "MLX did not return a valid response"
            case .generationFailed(let message):
                return "MLX generation failed: \(message)"
            case .modelLoadFailed(let message):
                return "Failed to load MLX model: \(message)"
            }
        }
    }

    // MARK: - Model Cache

    /// Thread-safe model cache using an actor to avoid reloading models.
    private actor ModelCache {
        private var cache: [String: ModelContainer] = [:]

        func get(_ path: String) -> ModelContainer? {
            cache[path]
        }

        func set(_ path: String, container: ModelContainer) {
            cache[path] = container
        }

        func clear() {
            cache.removeAll()
        }
    }

    private static let modelCache = ModelCache()

    // MARK: - Public API

    public static func checkAvailability() async -> Availability {
        // Native MLX is always available on Apple Silicon with this build.
        return Availability(
            pythonAvailable: false,
            mlxAvailable: true,
            mlxVersion: "native",
            nativeAvailable: true
        )
    }

    public static func generate(
        request: Request,
        progressHandler: (@Sendable (String) -> Void)? = nil
    ) async throws -> Response {
        do {
            let modelUrl = URL(fileURLWithPath: request.modelPath)

            // Check cache first
            let container: ModelContainer
            if let cached = await modelCache.get(request.modelPath) {
                container = cached
            } else {
                logger.info("Loading MLX model from: \(request.modelPath, privacy: .public)")
                let configuration = ModelConfiguration(directory: modelUrl)
                let loadedContainer = try await LLMModelFactory.shared.loadContainer(
                    configuration: configuration
                )
                await modelCache.set(request.modelPath, container: loadedContainer)
                container = loadedContainer
                logger.info("MLX model loaded successfully")
            }

            // Build chat messages for UserInput
            let chatMessages: [Chat.Message] = request.messages.map { msg in
                let role: Chat.Message.Role = switch msg.role {
                case "system": .system
                case "assistant": .assistant
                case "tool": .tool
                default: .user
                }
                return Chat.Message(role: role, content: msg.content)
            }

            let userInput = UserInput(chat: chatMessages)

            // Prepare input (tokenize with chat template)
            let lmInput = try await container.prepare(input: userInput)

            // Count prompt tokens
            let promptTokenCount = lmInput.text.tokens.size

            // Configure generation parameters
            let generateParameters = GenerateParameters(
                maxTokens: request.maxTokens,
                temperature: Float(request.temperature),
                topP: Float(request.topP)
            )

            // Generate via AsyncStream
            let stream = try await container.generate(
                input: lmInput,
                parameters: generateParameters
            )

            var outputText = ""
            var completionTokens = 0

            for await generation in stream {
                if Task.isCancelled { break }

                switch generation {
                case .chunk(let text):
                    outputText += text
                    completionTokens += 1
                    progressHandler?(text)

                case .info(let info):
                    completionTokens = info.generationTokenCount

                case .toolCall:
                    // Tool calls not handled at this level
                    break
                }
            }

            return Response(
                text: outputText,
                promptTokens: promptTokenCount,
                completionTokens: completionTokens,
                error: nil
            )
        } catch {
            logger.error(
                "Native MLX generation failed: \(error.localizedDescription, privacy: .public)"
            )
            throw MLXError.generationFailed(error.localizedDescription)
        }
    }

    /// Clear the model cache to free memory.
    public static func clearModelCache() async {
        await modelCache.clear()
    }
}
