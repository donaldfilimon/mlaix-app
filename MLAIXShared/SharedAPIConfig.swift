//
//  SharedAPIConfig.swift
//  MLAIXShared
//

import Foundation

/// Cross-platform API configuration for remote OpenAI-compatible endpoints.
/// API key is stored in Keychain; URL and model in UserDefaults.
@MainActor
public final class SharedAPIConfig {
    public static let shared = SharedAPIConfig()

    private let defaults = UserDefaults.standard
    private let keyBase = "com.donaldfilimon.mlaix.shared"
    private let apiKeyKey = "api_key"

    private init() {}

    public var apiBaseURL: URL? {
        get {
            guard let s = defaults.string(forKey: "\(keyBase).api_base_url"), !s.isEmpty else { return nil }
            return URL(string: s)
        }
        set { defaults.set(newValue?.absoluteString, forKey: "\(keyBase).api_base_url") }
    }

    /// API key stored in Keychain for security.
    public var apiKey: String? {
        get { KeychainHelper.get(key: "\(keyBase).\(apiKeyKey)") }
        set { KeychainHelper.set(key: "\(keyBase).\(apiKeyKey)", value: newValue) }
    }

    public var model: String? {
        get { defaults.string(forKey: "\(keyBase).model") ?? "gpt-4o-mini" }
        set { defaults.set(newValue, forKey: "\(keyBase).model") }
    }

    public var hasConfiguredAPI: Bool {
        apiBaseURL != nil && !(apiKey?.isEmpty ?? true)
    }
}
