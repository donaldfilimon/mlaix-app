//
//  KnownModelConcurrencyTests.swift
//  MLAITests
//
//  Tests for KnownModel thread-safety, model lookup, and reasoning detection.
//

import Foundation
import Testing

@testable import MLAI

struct KnownModelConcurrencyTests {

    @Test func testAvailableModelsThreadSafety() async {
        // Concurrent reads should all return the same snapshot
        let results = await withTaskGroup(of: Int.self, returning: [Int].self) { group in
            for _ in 0..<100 {
                group.addTask {
                    KnownModel.availableModels.count
                }
            }
            var counts: [Int] = []
            for await count in group {
                counts.append(count)
            }
            return counts
        }
        let unique = Set(results)
        #expect(unique.count == 1, "All concurrent reads should return consistent count, got \(unique)")
    }

}

// MARK: - Model Finding Tests

struct KnownModelFindingTests {

    private static func makeTestModels() -> [KnownModel] {
        [
            KnownModel(
                primaryName: "claude-sonnet-4-20250514",
                organization: .anthropic,
                modalities: [.text]
            ),
            KnownModel(
                primaryName: "gpt-4o-2024-11-20",
                organization: .openAi,
                modalities: [.text, .image]
            ),
            KnownModel(
                primaryName: "gemma-3-27b-it",
                organization: .google,
                modalities: [.text]
            ),
            KnownModel(
                primaryName: "deepseek-r1",
                organization: .deepSeek,
                modalities: [.text],
                capabilities: [.reasoning]
            ),
            KnownModel(
                primaryName: "qwen3-32b",
                organization: .qwen,
                modalities: [.text]
            ),
        ]
    }

    @Test func testExactMatchByPrimaryName() {
        let models = Self.makeTestModels()
        let found = KnownModel.findModel(byIdentifier: "claude-sonnet-4-20250514", in: models)
        #expect(found != nil)
        #expect(found?.organization == .anthropic)
    }

    @Test func testExactMatchCaseInsensitive() {
        let models = Self.makeTestModels()
        let found = KnownModel.findModel(byIdentifier: "Claude-Sonnet-4-20250514", in: models)
        #expect(found != nil)
        #expect(found?.organization == .anthropic)
    }

    @Test func testMatchWithProviderPrefix() {
        let models = Self.makeTestModels()
        let found = KnownModel.findModel(byIdentifier: "anthropic/claude-sonnet-4-20250514", in: models)
        #expect(found != nil)
        #expect(found?.organization == .anthropic)
    }

    @Test func testFullIdentifierMatch() {
        let models = Self.makeTestModels()
        let found = KnownModel.findModel(byIdentifier: "google/gemma-3-27b-it", in: models)
        #expect(found != nil)
        #expect(found?.organization == .google)
    }

    @Test func testNoMatchReturnsNil() {
        let models = Self.makeTestModels()
        let found = KnownModel.findModel(byIdentifier: "nonexistent-model-xyz", in: models)
        #expect(found == nil)
    }

    @Test func testEmptyModelsReturnsNil() {
        let found = KnownModel.findModel(byIdentifier: "claude-sonnet-4-20250514", in: [])
        #expect(found == nil)
    }

    @Test func testOrganizationFromString() {
        #expect(KnownModel.Organization.from(string: "anthropic") == .anthropic)
        #expect(KnownModel.Organization.from(string: "meta-llama") == .meta)
        #expect(KnownModel.Organization.from(string: "mistralai") == .mistral)
        #expect(KnownModel.Organization.from(string: "x-ai") == .xAi)
        #expect(KnownModel.Organization.from(string: "unknown-org") == nil)
    }

    @Test func testColonVariantNormalization() {
        let models = Self.makeTestModels()
        // Ollama-style "model:variant" normalizes to "model-variant"
        let found = KnownModel.findModel(byIdentifier: "deepseek-r1:latest", in: models)
        _ = found // Must not crash
    }

    @Test func testReasoningModelDetection() {
        let models = Self.makeTestModels()
        let found = KnownModel.findModel(byIdentifier: "deepseek-r1", in: models)
        #expect(found != nil)
        #expect(found?.capabilities.contains(.reasoning) == true)
        #expect(found?.isReasoningModel == true)
    }

    @Test func testVisionModelDetection() {
        let models = Self.makeTestModels()
        let found = KnownModel.findModel(byIdentifier: "gpt-4o-2024-11-20", in: models)
        #expect(found != nil)
        #expect(found?.isVision == true)
        #expect(found?.modalities.contains(.image) == true)
    }

    @Test func testNonVisionModel() {
        let models = Self.makeTestModels()
        let found = KnownModel.findModel(byIdentifier: "qwen3-32b", in: models)
        #expect(found != nil)
        #expect(found?.isVision == false)
    }
}

// MARK: - requiresExplicitReasoning Tests

struct KnownModelReasoningTests {

    @Test func testClaudeRequiresExplicitReasoning() {
        let model = KnownModel(
            primaryName: "claude-4-20250514",
            organization: .anthropic,
            modalities: [.text]
        )
        #expect(model.requiresExplicitReasoning == true)
    }

    @Test func testSonnetRequiresExplicitReasoning() {
        let model = KnownModel(
            primaryName: "sonnet-4-20250514",
            organization: .anthropic,
            modalities: [.text]
        )
        #expect(model.requiresExplicitReasoning == true)
    }

    @Test func testOlderClaudeDoesNotRequireExplicitReasoning() {
        let model = KnownModel(
            primaryName: "claude-3-haiku-20241022",
            organization: .anthropic,
            modalities: [.text]
        )
        #expect(model.requiresExplicitReasoning == false)
    }

    @Test func testGlmRequiresExplicitReasoning() {
        let model = KnownModel(
            primaryName: "glm-4.5-flash",
            organization: .zhipu,
            modalities: [.text]
        )
        #expect(model.requiresExplicitReasoning == true)
    }

    @Test func testNonAnthropicNonZhipuDoesNotRequire() {
        let model = KnownModel(
            primaryName: "gpt-4o",
            organization: .openAi,
            modalities: [.text]
        )
        #expect(model.requiresExplicitReasoning == false)
    }

    @Test func testGlmNotMatchedAsAnthropic() {
        // Ensure GLM models are NOT matched when org is Anthropic
        let model = KnownModel(
            primaryName: "glm-4.5-flash",
            organization: .anthropic,
            modalities: [.text]
        )
        // GLM pattern only applies to Zhipu, not Anthropic
        #expect(model.requiresExplicitReasoning == false)
    }
}
