//
//  InferenceSettingsTests.swift
//  MLAIXTests
//
//  Tests for InferenceSettings static properties and defaults.
//

import Foundation
import Testing
@testable import MLAIX

struct InferenceSettingsTests {

    @Test func testDefaultEndpoint() {
        #expect(InferenceSettings.defaultEndpoint == "https://router.huggingface.co/v1")
    }

    @Test func testMaxConsecutiveMalformedToolCalls() {
        #expect(InferenceSettings.maxConsecutiveMalformedToolCalls == 3)
    }

    @Test func testDefaultSystemPromptIsNonEmpty() {
        #expect(!InferenceSettings.defaultSystemPrompt.isEmpty)
        #expect(InferenceSettings.defaultSystemPrompt.contains("MLAI"))
    }

    @Test func testUseSourcesPromptIsNonEmpty() {
        #expect(!InferenceSettings.useSourcesPrompt.isEmpty)
    }

    @Test func testUseFunctionsPromptIsNonEmpty() {
        #expect(!InferenceSettings.useFunctionsPrompt.isEmpty)
    }

    @Test func testMetadataPromptContainsUserPlaceholder() {
        #expect(InferenceSettings.metadataPrompt.contains("user"))
    }
}
