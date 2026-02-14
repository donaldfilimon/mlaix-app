//
//  LlamaServer+Networking.swift
//  MLAI
//
//  Created by Bean John on 10/9/24.
//

import Foundation
import FSKit_macOS
import OSLog

extension LlamaServer {
    
    // MARK: - URL Helpers
    
    /// Function to get the `URL` at which the inference server is accessible
    /// - Parameter path: The endpoint accessed via this `URL`
    /// - Returns: The `URL` at which the inference server is accessible
    func url(
        _ path: String,
        openAiCompatiblePath: Bool,
        canReachRemoteServer: Bool,
        mustUseLocalServer: Bool = false
    ) async -> (
        url: URL,
        usingRemoteServer: Bool
    ) {
        // Check endpoint
        let endpoint: String = InferenceSettings.endpoint.replacingSuffix(
            "/chat/completions",
            with: ""
        )
        let urlString: String
        let notUsingServer: Bool = !canReachRemoteServer || !InferenceSettings.useServer
        if notUsingServer || mustUseLocalServer {
            let addV1: String = openAiCompatiblePath ? "/v1" : ""
            urlString = "\(self.scheme)://\(self.host):\(self.port)\(addV1)\(path)"
        } else {
            urlString = "\(endpoint)\(path)"
        }
        guard let url = URL(string: urlString) else {
            Self.logger.warning("Invalid inference URL '\(urlString, privacy: .public)'; falling back to localhost")
            // Safe: this literal URL is always valid
            let fallback = URL(string: "http://localhost:4579")!
            return (fallback, !notUsingServer)
        }
        return (url, !notUsingServer)
    }
    
    /// Function to get a list of available models on the server
    public static func getAvailableModels() async -> [String] {
        let rawEndpoint = InferenceSettings.endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !rawEndpoint.isEmpty else {
            return []
        }
        
        let normalizedEndpoint = rawEndpoint
            .replacingSuffix("/chat/completions", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let baseEndpoint = "https://openrouter.ai/api/v1"
        let isOpenRouterEndpoint = normalizedEndpoint.hasPrefix(baseEndpoint)
        
        if isOpenRouterEndpoint,
           let cachedModels = KnownModel.loadModelsFromFile(),
           !cachedModels.isEmpty {
            return cachedModels.map(keyPath: \.fullIdentifier)
        }
        
        guard let baseURL = URL(string: normalizedEndpoint) else {
            Self.logger.error("Invalid inference endpoint '\(normalizedEndpoint, privacy: .public)'")
            return []
        }
        
        let modelsEndpoint = baseURL.appendingPathComponent("models")
        var request = URLRequest(url: modelsEndpoint)
        request.httpMethod = "GET"
        
        let apiKey = InferenceSettings.inferenceApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if !apiKey.isEmpty {
            request.setValue(
                "Bearer \(apiKey)",
                forHTTPHeaderField: "Authorization"
            )
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let urlSession = URLSession.shared
        urlSession.configuration.waitsForConnectivity = false
        urlSession.configuration.timeoutIntervalForRequest = 2
        urlSession.configuration.timeoutIntervalForResource = 2
        
        do {
            let (data, _) = try await urlSession.data(for: request)
            
            let decoder = JSONDecoder()
            let response = try decoder.decode(
                AvailableModelsResponse.self,
                from: data
            )
            let models = response.data.map(\.id)
            
            if models.isEmpty,
               isOpenRouterEndpoint,
               let cachedModels = KnownModel.loadModelsFromFile() {
                return cachedModels.map(keyPath: \.fullIdentifier)
            }
            
            Self.logger.info("Fetched \(models.count, privacy: .public) models from endpoint '\(modelsEndpoint.absoluteString, privacy: .public)'")
            return models.sortedByModelSize()
        } catch {
            Self.logger.error("Failed to fetch models from endpoint '\(modelsEndpoint.absoluteString, privacy: .public)': \(error.localizedDescription, privacy: .public)")
            
            if isOpenRouterEndpoint,
               let cachedModels = KnownModel.loadModelsFromFile(),
               !cachedModels.isEmpty {
                return cachedModels.map(keyPath: \.fullIdentifier)
            }
            
            return []
        }
    }
    
    /// Function to get number of tokens in a piece of text
    /// - Parameter text: The text for which the number of tokens is calculated
    /// - Returns: The number of tokens in the text
    public func tokenCount(
        in text: String,
        canReachRemoteServer: Bool
    ) async throws -> Int {
        // Start server if not active
        if !self.process.isRunning && !self.isStartingServer {
            try await self.startServer(
                canReachRemoteServer: canReachRemoteServer
            )
        }
		// Get url of endpoint
		guard let rawUrl = URL(string: "\(self.scheme)://\(self.host):\(self.port)/tokenize") else {
			throw LlamaServerError.modelError
		}
        // Formulate request
        var request = URLRequest(
            url: rawUrl
        )
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("keep-alive", forHTTPHeaderField: "Connection")
        let requestParams: TokenizeParams = .init(content: text)
        let requestJson: String = requestParams.toJSON()
        request.httpBody = requestJson.data(using: .utf8)
        // Send request
        let (data, _) = try await URLSession.shared.data(
            for: request
        )
        let response: TokenizeResponse = try JSONDecoder().decode(
            TokenizeResponse.self,
            from: data
        )
        return response.count
    }
    
}

// MARK: - Networking Types

extension LlamaServer {
    
    struct AvailableModelsResponse: Codable {
        var data: [AvailableModel]
    }
    
    struct AvailableModel: Codable {
        var id: String
    }
    
    public struct TokenizeParams: Codable {
        
        let content: String
        
        /// Function to convert chat parameters to JSON
        func toJSON() -> String {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            guard let jsonData = try? encoder.encode(self),
                  let str = String(data: jsonData, encoding: .utf8) else {
                return "{}"
            }
            return str
        }
        
    }
    
    struct TokenizeResponse: Codable {
        
        var tokens: [Int]?
        var count: Int {
            return self.tokens?.count ?? 0
        }
        
    }
    
}



