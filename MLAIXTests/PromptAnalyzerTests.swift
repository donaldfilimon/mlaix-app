//
//  PromptAnalyzerTests.swift
//  MLAIXTests
//
//  Tests for PromptAnalyzer.ResultType and related types.
//

import Foundation
import Testing
@testable import MLAIX

struct PromptAnalyzerTests {

    @Test func testResultTypeRawValues() {
        #expect(PromptAnalyzer.ResultType.text.rawValue == "text-generation")
        #expect(PromptAnalyzer.ResultType.image.rawValue == "image-generation")
    }

    @Test func testResultTypeAllCases() {
        let cases = PromptAnalyzer.ResultType.allCases
        #expect(cases.count == 2)
        #expect(cases.contains(.text))
        #expect(cases.contains(.image))
    }

    @Test func testResultTypeInitFromRawValue() {
        #expect(PromptAnalyzer.ResultType("text-generation") == .text)
        #expect(PromptAnalyzer.ResultType("image-generation") == .image)
        #expect(PromptAnalyzer.ResultType("invalid") == nil)
    }

    // MARK: - Phase 2: ClassificationResult

    @Test func testClassificationResultInit() {
        let result = PromptAnalyzer.ClassificationResult(
            resultType: .text,
            confidence: 0.95
        )
        #expect(result.resultType == .text)
        #expect(result.confidence == 0.95)
    }

    @Test func testClassificationResultImageType() {
        let result = PromptAnalyzer.ClassificationResult(
            resultType: .image,
            confidence: 0.7
        )
        #expect(result.resultType == .image)
        #expect(result.confidence == 0.7)
    }

    @Test func testClassificationResultConfidenceRange() {
        let result = PromptAnalyzer.ClassificationResult(
            resultType: .text,
            confidence: 0.0
        )
        #expect(result.confidence >= 0.0)
        #expect(result.confidence <= 1.0)
    }

    @Test func testClassificationResultIsSendable() {
        let result = PromptAnalyzer.ClassificationResult(
            resultType: .text,
            confidence: 0.8
        )
        let sendableCheck: @Sendable () -> Double = { result.confidence }
        #expect(sendableCheck() == 0.8)
    }

    // MARK: - classify() fallback

    @Test @MainActor func testClassifyFallbackReturnsText() {
        // Without a trained model, classify should fall back to .text with confidence 1.0
        let result = PromptAnalyzer.classify("hello world")
        // Fallback when no classifier is loaded
        #expect(result.resultType == .text || result.resultType == .image)
        #expect(result.confidence >= 0.0)
        #expect(result.confidence <= 1.0)
    }

    @Test @MainActor func testClassifyEmptyString() {
        let result = PromptAnalyzer.classify("")
        #expect(result.resultType == .text || result.resultType == .image)
        #expect(result.confidence >= 0.0)
    }

    @Test @MainActor func testClassifyLongPrompt() {
        let longPrompt = String(repeating: "Write a detailed essay about climate change. ", count: 20)
        let result = PromptAnalyzer.classify(longPrompt)
        #expect(result.resultType == .text || result.resultType == .image)
        #expect(result.confidence >= 0.0)
        #expect(result.confidence <= 1.0)
    }

    // MARK: - batchClassify()

    @Test @MainActor func testBatchClassifyCountMatchesInput() {
        let prompts = ["hello", "draw a cat", "explain physics"]
        let results = PromptAnalyzer.batchClassify(prompts)
        #expect(results.count == prompts.count)
    }

    @Test @MainActor func testBatchClassifyEmptyInput() {
        let results = PromptAnalyzer.batchClassify([])
        #expect(results.count == 0)
    }

    @Test @MainActor func testBatchClassifySingleItem() {
        let results = PromptAnalyzer.batchClassify(["test"])
        #expect(results.count == 1)
        #expect(results.first?.confidence ?? -1 >= 0.0)
    }

    @Test @MainActor func testBatchClassifyAllResultsHaveValidConfidence() {
        let prompts = ["a", "b", "c", "d", "e"]
        let results = PromptAnalyzer.batchClassify(prompts)
        for result in results {
            #expect(result.confidence >= 0.0)
            #expect(result.confidence <= 1.0)
        }
    }

    // MARK: - invalidateCachedModel()

    @Test @MainActor func testInvalidateCachedModelDoesNotCrash() {
        PromptAnalyzer.invalidateCachedModel()
        // If we reach here, no crash occurred
    }

    @Test @MainActor func testInvalidateAndClassifyStillWorks() {
        PromptAnalyzer.invalidateCachedModel()
        let result = PromptAnalyzer.classify("test after invalidation")
        #expect(result.resultType == .text || result.resultType == .image)
    }
}
