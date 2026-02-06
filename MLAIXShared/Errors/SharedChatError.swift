//
//  SharedChatError.swift
//  MLAIXShared
//

import Foundation

/// Structured errors for chat/API operations across platforms.
public enum SharedChatError: LocalizedError, Sendable {
    case apiNotConfigured
    case apiKeyMissing
    case invalidURL(String)
    case networkError(underlying: String)
    case apiError(statusCode: Int, bodyPreview: String)
    case invalidResponse
    case encodingFailed

    public var errorDescription: String? {
        switch self {
        case .apiNotConfigured:
            return "API endpoint not configured"
        case .apiKeyMissing:
            return "API key not configured"
        case .invalidURL(let detail):
            return "Invalid API URL: \(detail)"
        case .networkError(let underlying):
            return "Network error: \(underlying)"
        case .apiError(let code, let body):
            return "API error \(code): \(body)"
        case .invalidResponse:
            return "Invalid API response"
        case .encodingFailed:
            return "Failed to encode request"
        }
    }
}
