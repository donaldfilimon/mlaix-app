//
//  SharedChatErrorTests.swift
//  MLAIXSharedTests
//

import Foundation
import Testing
@testable import MLAIXShared

struct SharedChatErrorTests {

    @Test func testApiNotConfiguredDescription() {
        let err = SharedChatError.apiNotConfigured
        #expect(err.errorDescription == "API endpoint not configured")
    }

    @Test func testApiKeyMissingDescription() {
        let err = SharedChatError.apiKeyMissing
        #expect(err.errorDescription == "API key not configured")
    }

    @Test func testInvalidURLDescription() {
        let err = SharedChatError.invalidURL("bad")
        #expect(err.errorDescription == "Invalid API URL: bad")
    }

    @Test func testNetworkErrorDescription() {
        let err = SharedChatError.networkError(underlying: "timeout")
        #expect(err.errorDescription == "Network error: timeout")
    }

    @Test func testApiErrorDescription() {
        let err = SharedChatError.apiError(statusCode: 401, bodyPreview: "Unauthorized")
        #expect(err.errorDescription?.contains("401") == true)
        #expect(err.errorDescription?.contains("Unauthorized") == true)
    }

    @Test func testLocalizedErrorConformance() {
        let err = SharedChatError.invalidResponse
        #expect(err.errorDescription == "Invalid API response")
    }
}
