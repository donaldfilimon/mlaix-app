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

    /// Availability status for each backend type.
    public struct BackendAvailability: Sendable {
        public let local: Bool
        public let remote: Bool
        public let foundationModels: Bool
        public let recommendedBackend: RecommendedBackend
        public let canAutoConnect: Bool

        public enum RecommendedBackend: String, Sendable {
            case local
            case remote
            case foundationModels
            case none
        }
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
    public static func probeAvailability() async -> BackendAvailability {
        let foundationAvailable = FoundationModelsSupport.isAvailable
        let localAvailable = (Settings.modelUrl?.path).map { FileManager.default.fileExists(atPath: $0) } ?? false
        let remoteReachable = await probeRemoteEndpoint()

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
        } else if foundationAvailable {
            recommended = .foundationModels
            canAutoConnect = true
        } else if remoteReachable {
            recommended = .remote
            canAutoConnect = true
        } else {
            recommended = .none
            canAutoConnect = false
        }

        Self.logger.info(
            "Backend probe: local=\(localAvailable) remote=\(remoteReachable) foundation=\(foundationAvailable) recommended=\(recommended.rawValue)"
        )

        return BackendAvailability(
            local: localAvailable,
            remote: remoteReachable,
            foundationModels: foundationAvailable,
            recommendedBackend: recommended,
            canAutoConnect: canAutoConnect
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
            InferenceSettings.useServer = true
            InferenceSettings.useFoundationModels = false
            Self.logger.notice("Auto-configured: Remote API at \(InferenceSettings.endpoint, privacy: .public)")
            return true
        case .local:
            InferenceSettings.useServer = false
            InferenceSettings.useFoundationModels = false
            Self.logger.notice("Auto-configured: Local model")
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
