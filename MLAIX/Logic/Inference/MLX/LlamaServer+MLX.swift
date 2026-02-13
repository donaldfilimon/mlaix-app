//
//  LlamaServer+MLX.swift
//  MLAI
//
//  Created by Codex on 2/5/26.
//

import Foundation
import FSKit_macOS
import OSLog

extension LlamaServer {

    private static let mlxLogger: Logger = .init(
        subsystem: Bundle.main.logSubsystem,
        category: "MLXInference"
    )

    private func mlxMessages(
        from messages: [Message.MessageSubset]
    ) -> [MLXRunner.Message] {
        messages.map { message in
            let role: String = {
                switch message.role {
                case .system:
                    return "system"
                case .assistant:
                    return "assistant"
                case .user:
                    return "user"
                }
            }()
            let content: String = {
                switch message.content {
                case .textOnly(let text):
                    return text
                case .multimodal(let contents):
                    let textParts = contents.compactMap { item -> String? in
                        if case let .text(text) = item {
                            return text
                        }
                        return nil
                    }
                    if !textParts.isEmpty {
                        return textParts.joined(separator: "\n")
                    }
                    return "[Image omitted]"
                }
            }()
            return MLXRunner.Message(role: role, content: content)
        }
    }

    private func mlxFallbackPrompt(
        from messages: [MLXRunner.Message]
    ) -> String {
        messages.map { message in
            let roleLabel = message.role.capitalized
            return "\(roleLabel): \(message.content)"
        }.joined(separator: "\n\n")
    }

    private func mlxMaxTokens(
        promptTokenEstimate: Int
    ) -> Int {
        let contextLength = InferenceSettings.contextLength
        let fallbackContext = contextLength > 0 ? contextLength : 8_192
        let available = max(128, fallbackContext - promptTokenEstimate)
        let userMax = max(128, InferenceSettings.mlxMaxTokens)
        return min(userMax, available)
    }

    func getMLXChatCompletion(
        params: ChatParameters,
        progressHandler: (@Sendable (String) -> Void)? = nil
    ) async throws -> CompleteResponse {
        guard let modelUrl = self.modelUrl else {
            throw LlamaServerError.modelError
        }
        guard modelUrl.fileExists else {
            throw LlamaServerError.modelError
        }
        if Task.isCancelled {
            throw LlamaServerError.cancelled
        }

        let mlxMessages = self.mlxMessages(from: params.messages)
        let fallbackPrompt = mlxFallbackPrompt(from: mlxMessages)
        let promptTokenEstimate = max(1, fallbackPrompt.estimatedTokenCount)
        let maxTokens = mlxMaxTokens(promptTokenEstimate: promptTokenEstimate)

        let request = MLXRunner.Request(
            modelPath: modelUrl.path,
            messages: mlxMessages,
            maxTokens: maxTokens,
            temperature: params.temperature,
            topP: min(max(InferenceSettings.mlxTopP, 0.05), 1.0)
        )

        let start = CFAbsoluteTimeGetCurrent()
        let response: MLXRunner.Response
        do {
            response = try await MLXRunner.generate(
                request: request,
                progressHandler: progressHandler
            )
        } catch let error as MLXRunner.MLXError {
            Self.mlxLogger.error("MLX inference failed: \(error.localizedDescription, privacy: .public)")
            throw LlamaServerError.errorResponse(error.localizedDescription)
        } catch {
            Self.mlxLogger.error("MLX inference failed: \(error.localizedDescription, privacy: .public)")
            throw LlamaServerError.errorResponse(error.localizedDescription)
        }

        if Task.isCancelled {
            throw LlamaServerError.cancelled
        }

        let outputText = response.text ?? ""

        let inputTokens = response.promptTokens ?? promptTokenEstimate
        let outputTokens = response.completionTokens ?? max(1, outputText.estimatedTokenCount)
        let totalTokens = inputTokens + outputTokens
        let generationTime = CFAbsoluteTimeGetCurrent() - start
        let tokensPerSecond = generationTime > 0 ? Double(outputTokens) / generationTime : 0

        let record = InferenceRecord(
            name: self.modelName,
            startTime: Date(timeIntervalSinceReferenceDate: start),
            type: .chatCompletions,
            endpoint: nil,
            inputTokens: inputTokens,
            outputTokens: outputTokens,
            tokensPerSecond: tokensPerSecond
        )
        await InferenceRecords.shared.add(record)

        let usage = Usage(
            completion_tokens: outputTokens,
            prompt_tokens: inputTokens,
            total_tokens: totalTokens
        )

        return CompleteResponse(
            text: outputText,
            responseStartSeconds: generationTime,
            predictedPerSecond: tokensPerSecond,
            modelName: self.modelName,
            usage: usage,
            usedServer: false,
            blockFunctionCalls: nil,
            malformedToolCalls: nil
        )
    }
}
