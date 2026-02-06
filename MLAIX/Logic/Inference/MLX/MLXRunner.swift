//
//  MLXRunner.swift
//  MLAI
//
//  Created by Codex on 2/5/26.
//

import Foundation
import OSLog

public enum MLXRunner {
    static let logger: Logger = .init(
        subsystem: Bundle.main.logSubsystem,
        category: String(describing: MLXRunner.self)
    )

    public struct Availability: Sendable {
        let pythonAvailable: Bool
        let mlxAvailable: Bool
        let mlxVersion: String?
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

        public var errorDescription: String? {
            switch self {
            case .pythonUnavailable:
                return "Python is not available"
            case .invalidResponse:
                return "MLX did not return a valid response"
            case .generationFailed(let message):
                return "MLX generation failed: \(message)"
            }
        }
    }

    public static func checkAvailability() async -> Availability {
        await Task.detached(priority: .userInitiated) {
            guard PythonRunner.isPythonInstalled() else {
                return Availability(
                    pythonAvailable: false,
                    mlxAvailable: false,
                    mlxVersion: nil
                )
            }
            let pythonCode = """
import importlib.util
import json

spec = importlib.util.find_spec("mlx_lm")
mlx_available = spec is not None
version = None
if mlx_available:
    try:
        import mlx_lm
        version = getattr(mlx_lm, "__version__", None)
    except Exception:
        version = None

print(json.dumps({
    "mlx_available": mlx_available,
    "version": version
}))
"""
            do {
                let output = try PythonRunner.executePython(pythonCode)
                if let availability = parseAvailabilityOutput(output) {
                    return Availability(
                        pythonAvailable: true,
                        mlxAvailable: availability.mlxAvailable,
                        mlxVersion: availability.mlxVersion
                    )
                }
            } catch {
                logger.error("Failed to check MLX availability: \(error.localizedDescription, privacy: .public)")
            }
            return Availability(
                pythonAvailable: true,
                mlxAvailable: false,
                mlxVersion: nil
            )
        }.value
    }

    private static func parseAvailabilityOutput(
        _ output: String
    ) -> Availability? {
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let start = trimmed.lastIndex(of: "{"),
              let end = trimmed.lastIndex(of: "}"),
              start <= end else {
            return nil
        }
        let jsonString = String(trimmed[start...end])
        struct AvailabilityPayload: Codable {
            let mlx_available: Bool
            let version: String?
        }
        guard let data = jsonString.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(AvailabilityPayload.self, from: data) else {
            return nil
        }
        return Availability(
            pythonAvailable: true,
            mlxAvailable: decoded.mlx_available,
            mlxVersion: decoded.version
        )
    }

    public static func generate(
        request: Request
    ) async throws -> Response {
        guard PythonRunner.isPythonInstalled() else {
            throw MLXError.pythonUnavailable
        }
        let encoder = JSONEncoder()
        let payloadData = try encoder.encode(request)
        let payloadBase64 = payloadData.base64EncodedString()
        let pythonCode = """
import base64
import contextlib
import io
import json

payload = json.loads(base64.b64decode(\"\(payloadBase64)\").decode(\"utf-8\"))
model_path = payload.get(\"model_path\")
messages = payload.get(\"messages\", [])
max_tokens = int(payload.get(\"max_tokens\", 1024))
temperature = float(payload.get(\"temperature\", 0.7))
top_p = float(payload.get(\"top_p\", 1.0))


def build_prompt(messages, tokenizer):
    if hasattr(tokenizer, \"apply_chat_template\"):
        try:
            return tokenizer.apply_chat_template(messages, tokenize=False, add_generation_prompt=True)
        except Exception:
            pass
    lines = []
    for message in messages:
        role = message.get(\"role\", \"user\")
        content = message.get(\"content\", \"\")
        lines.append(f\"{role.capitalize()}: {content}\")
    return "\\n\\n".join(lines)

try:
    from mlx_lm import load, generate

    with contextlib.redirect_stdout(io.StringIO()):
        model, tokenizer = load(model_path)

    prompt = build_prompt(messages, tokenizer)

    with contextlib.redirect_stdout(io.StringIO()):
        output = generate(
            model,
            tokenizer,
            prompt=prompt,
            max_tokens=max_tokens,
            temp=temperature,
            top_p=top_p,
            verbose=False
        )

    try:
        prompt_tokens = len(tokenizer.encode(prompt))
    except Exception:
        prompt_tokens = None

    try:
        completion_tokens = len(tokenizer.encode(output))
    except Exception:
        completion_tokens = None

    print(json.dumps({
        \"text\": output,
        \"prompt_tokens\": prompt_tokens,
        \"completion_tokens\": completion_tokens
    }))
except Exception as error:
    print(json.dumps({\"error\": str(error)}))
"""
        let output = try await Task.detached(priority: .userInitiated) {
            try PythonRunner.executePython(pythonCode)
        }.value
        let trimmedOutput = output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = trimmedOutput.data(using: .utf8) else {
            throw MLXError.invalidResponse
        }
        let decoder = JSONDecoder()
        let response = try decoder.decode(Response.self, from: data)
        if let error = response.error, !error.isEmpty {
            throw MLXError.generationFailed(error)
        }
        guard response.text != nil else {
            throw MLXError.invalidResponse
        }
        return response
    }
}
