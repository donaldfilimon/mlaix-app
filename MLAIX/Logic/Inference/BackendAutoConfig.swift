//
//  BackendAutoConfig.swift
//  MLAI
//
//  Auto-detects available inference backends and recommends or applies configuration.
//

import Foundation
import OSLog

/// Probes available backends and provides auto-configuration recommendations.
@MainActor
public enum BackendAutoConfig {

    private static let logger = Logger(
        subsystem: Bundle.main.logSubsystem,
        category: String(describing: BackendAutoConfig.self)
    )

    /// Well-known local server endpoints (OpenAI-compatible). Probed in order when no backend is configured; llama.cpp is last fallback.
    private static let localServerCandidates: [(name: String, baseURL: String)] = [
        ("Ollama", "http://localhost:11434/v1"),
        ("LM Studio", "http://localhost:1234/v1"),
        ("MLX CLI", "http://localhost:8080/v1"),
        ("Llama.cpp server", "http://localhost:4579/v1"),
    ]

    /// Availability status for each backend type.
    public struct BackendAvailability: Sendable {
        public let local: Bool
        public let remote: Bool
        public let foundationModels: Bool
        public let mlx: Bool
        public let recommendedBackend: RecommendedBackend
        public let canAutoConnect: Bool
        /// When set, caller should use this endpoint for remote (e.g. auto-detected Ollama/LM Studio/MLX CLI).
        public let suggestedRemoteEndpoint: String?

        public enum RecommendedBackend: String, Sendable {
            case local
            case remote
            case foundationModels
            case mlx
            case none
        }
    }

    /// Probes well-known local servers (Ollama, LM Studio, MLX CLI, Llama.cpp). Returns first reachable endpoint.
    private static func probeLocalServers(timeout: TimeInterval = 1.5) async -> (name: String, endpoint: String)? {
        for candidate in localServerCandidates {
            let base = candidate.baseURL.replacingSuffix("/", with: "")
            for path in ["models", "chat/completions"] {
                let urlString = "\(base)/\(path)"
                guard let url = URL(string: urlString) else { continue }
                if await url.isAPIEndpointReachable(timeout: timeout) {
                    Self.logger.info("Local server '\(candidate.name)' reachable at \(candidate.baseURL)")
                    return (candidate.name, candidate.baseURL)
                }
            }
        }
        return nil
    }

    /// Probes remote endpoint directly (does not require useServer to be true).
    private static func probeRemoteEndpoint(timeout: TimeInterval = 2.0) async -> Bool {
        let endpoint = InferenceSettings.endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !endpoint.isEmpty else { return false }
        let base = endpoint.replacingSuffix("/chat/completions", with: "").replacingSuffix("/", with: "")
        let testPaths = ["models", "chat/completions"]
        for path in testPaths {
            let urlString = base.hasSuffix("/") ? base + path : "\(base)/\(path)"
            guard let url = URL(string: urlString) else { continue }
            if await url.isAPIEndpointReachable(timeout: timeout) {
                return true
            }
        }
        return false
    }

    /// Probes all backends and returns availability. Does not modify settings.
    /// When current endpoint is empty or default and unreachable, probes Ollama / LM Studio / MLX CLI; if one is reachable, sets suggestedRemoteEndpoint.
    public static func probeAvailability() async -> BackendAvailability {
        let foundationAvailable = FoundationModelsSupport.isAvailable
        let localAvailable = (Settings.modelUrl?.path).map { FileManager.default.fileExists(atPath: $0) } ?? false
        var remoteReachable = await probeRemoteEndpoint()
        var suggestedRemoteEndpoint: String? = nil
        let currentEndpoint = InferenceSettings.endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        let isDefaultOrEmpty = currentEndpoint.isEmpty || currentEndpoint == InferenceSettings.defaultEndpoint
        if !remoteReachable, isDefaultOrEmpty, let local = await probeLocalServers() {
            suggestedRemoteEndpoint = local.endpoint
            remoteReachable = true
        }
        let mlxAvailability = await MLXRunner.checkAvailability()
        let mlxAvailable = mlxAvailability.mlxAvailable

        // Priority cascade: Foundation Models → Remote → Local llama.cpp → MLX
        let recommended: BackendAvailability.RecommendedBackend
        let canAutoConnect: Bool

        if foundationAvailable {
            recommended = .foundationModels
            canAutoConnect = true
        } else if remoteReachable {
            recommended = .remote
            canAutoConnect = true
        } else if localAvailable {
            recommended = .local
            canAutoConnect = true
        } else if mlxAvailable {
            recommended = .mlx
            canAutoConnect = true
        } else {
            recommended = .none
            canAutoConnect = false
        }

        Self.logger.info(
            "Backend probe: local=\(localAvailable) remote=\(remoteReachable) foundation=\(foundationAvailable) mlx=\(mlxAvailable) recommended=\(recommended.rawValue)"
        )

        return BackendAvailability(
            local: localAvailable,
            remote: remoteReachable,
            foundationModels: foundationAvailable,
            mlx: mlxAvailable,
            recommendedBackend: recommended,
            canAutoConnect: canAutoConnect,
            suggestedRemoteEndpoint: suggestedRemoteEndpoint
        )
    }

    /// Applies recommended configuration when no backend is currently usable.
    /// Returns true if config was applied.
    public static func autoConfigureIfNeeded() async -> Bool {
        guard !Settings.hasModel else {
            Self.logger.debug("Model already configured, skipping auto-config")
            return false
        }

        let availability = await probeAvailability()
        guard availability.canAutoConnect else {
            Self.logger.warning("No backend available for auto-config")
            return false
        }

        switch availability.recommendedBackend {
        case .foundationModels:
            InferenceSettings.useFoundationModels = true
            InferenceSettings.useServer = false
            Self.logger.notice("Auto-configured: Apple Foundation Models")
            return true
        case .remote:
            if let suggested = availability.suggestedRemoteEndpoint {
                InferenceSettings.endpoint = suggested
            }
            InferenceSettings.useServer = true
            InferenceSettings.useFoundationModels = false
            Self.logger.notice("Auto-configured: Remote API at \(InferenceSettings.endpoint, privacy: .public)")
            return true
        case .local:
            InferenceSettings.useServer = false
            InferenceSettings.useFoundationModels = false
            Self.logger.notice("Auto-configured: Local model")
            return true
        case .mlx:
            InferenceSettings.useServer = false
            InferenceSettings.useFoundationModels = false
            Self.logger.notice("Auto-configured: MLX backend")
            return true
        case .none:
            return false
        }
    }

    /// Refreshes backend connectivity (e.g. after network change). Updates Model.shared state.
    public static func refreshConnectivity() async {
        let _ = await Model.shared.remoteServerIsReachable()
    }
}
