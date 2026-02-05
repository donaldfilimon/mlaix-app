//
//  ModelNameFormatterTests.swift
//  MLAITests
//
//  Tests for model name formatting and search matching utilities.
//

import Testing
@testable import MLAI

struct ModelNameFormatterTests {

    @Test func testFormatsKnownModelWithVariantSuffix() {
        let models = [
            KnownModel(
                primaryName: "openai/gpt-4o-mini:free",
                displayName: nil,
                organization: .openAi
            )
        ]

        let formatted = ModelNameFormatter.formatModelName(
            "openai/gpt-4o-mini:free",
            knownModels: models
        )

        #expect(formatted == "OpenAI: openai/gpt-4o-mini (free)")
    }

    @Test func testFormatsKnownModelWithDisplayName() {
        let models = [
            KnownModel(
                primaryName: "acme/alpha:preview",
                displayName: "Alpha Preview",
                organization: .other,
                organizationIdentifier: "Acme"
            )
        ]

        let formatted = ModelNameFormatter.formatModelName(
            "acme/alpha:preview",
            knownModels: models
        )

        #expect(formatted == "Acme: Alpha Preview")
    }

    @Test func testFormatsUnknownModelWithProviderAndVariant() {
        let formatted = ModelNameFormatter.formatModelName(
            "custom/model:XL",
            knownModels: []
        )

        #expect(formatted == "Custom: model XL")
    }
}

struct ModelSearchMatcherTests {

    @Test func testFuzzyMatchFindsPrefixAndSubstring() {
        #expect(ModelSearchMatcher.fuzzyMatch("OpenAI GPT-4o mini", query: "gpt4"))
        #expect(ModelSearchMatcher.fuzzyMatch("deepseek r1", query: "deep"))
        #expect(ModelSearchMatcher.fuzzyMatch("meta-llama 3", query: "llam"))
    }

    @Test func testFuzzyMatchRejectsNonMatches() {
        #expect(!ModelSearchMatcher.fuzzyMatch("Claude Sonnet", query: "llama"))
        #expect(!ModelSearchMatcher.fuzzyMatch("Qwen 2.5", query: "grok"))
    }
}
