//
//  ModelNameFormatterTests.swift
//  MLAITests
//
//  Tests for model name formatting and search matching utilities.
//

import Testing
@testable import MLAIX

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

    @Test(arguments: [
        ("OpenAI GPT-4o mini", "gpt4", true),
        ("deepseek r1", "deep", true),
        ("meta-llama 3", "llam", true),
        ("Claude Sonnet", "llama", false),
        ("Qwen 2.5", "grok", false)
    ])
    func testFuzzyMatch(modelName: String, query: String, expectedMatch: Bool) {
        #expect(ModelSearchMatcher.fuzzyMatch(modelName, query: query) == expectedMatch,
            "\(modelName) with query '\(query)' should \(expectedMatch ? "match" : "not match")")
    }
}
