//
//  ExtensionStringTests.swift
//  MLAIXTests
//
//  Tests for Extension+String (reasoningProcess, reasoningRemoved, specialReasoningTokens).
//

import Foundation
import Testing
@testable import MLAIX

struct ExtensionStringTests {

    // MARK: - specialReasoningTokens

    @Test func testSpecialReasoningTokensStructure() {
        let tokens = String.specialReasoningTokens
        #expect(tokens.count == 2)
        #expect(tokens[0] == ["<think>", "</think>"])
        #expect(tokens[1] == ["<thought>", "</thought>"])
        for set in tokens {
            #expect(set.count == 2, "Each token set must have start and end")
        }
    }

    // MARK: - reasoningProcess

    @Test func testReasoningProcessExtractsThinkContent() {
        let input = "Hello <think>internal reasoning here</think> world"
        let result = input.reasoningProcess
        #expect(result == "internal reasoning here")
    }

    @Test func testReasoningProcessExtractsThoughtContent() {
        let input = "Before <thought>step one</thought> after"
        let result = input.reasoningProcess
        #expect(result == "step one")
    }

    @Test func testReasoningProcessReturnsNilWhenNoTokens() {
        let input = "Plain text with no reasoning tokens"
        #expect(input.reasoningProcess == nil)
    }

    @Test func testReasoningProcessReturnsNilWhenOnlyStartToken() {
        let input = "Incomplete <think>no end"
        #expect(input.reasoningProcess == nil)
    }

    @Test func testReasoningProcessTrimsWhitespace() {
        let input = "x <think>  \n  content  \n </think> y"
        let result = input.reasoningProcess
        #expect(result == "content")
    }

    @Test func testReasoningProcessPrefersFirstMatchingSet() {
        let input = "<think>first</think> and <thought>second</thought>"
        let result = input.reasoningProcess
        #expect(result == "first")
    }

    // MARK: - reasoningRemoved

    @Test func testReasoningRemovedStripsThinkContent() {
        let input = "Hello <think>internal reasoning</think> world"
        let result = input.reasoningRemoved
        #expect(result == "Hello  world", "Removal leaves space where tokens were")
    }

    @Test func testReasoningRemovedStripsThoughtContent() {
        let input = "Before <thought>step</thought> after"
        let result = input.reasoningRemoved
        #expect(result == "Before  after", "Removal leaves space where tokens were")
    }

    @Test func testReasoningRemovedReturnsEmptyWhenOnlyStartToken() {
        let input = "Bad <think>no end token"
        let result = input.reasoningRemoved
        #expect(result == "")
    }

    @Test func testReasoningRemovedLeavesPlainTextUnchanged() {
        let input = "No special tokens here"
        let result = input.reasoningRemoved
        #expect(result == "No special tokens here")
    }

    @Test func testReasoningRemovedTrimsResult() {
        let input = " <think>x</think> "
        let result = input.reasoningRemoved
        #expect(result == "")
    }

    @Test(arguments: [
        ("<think>a</think>", "a"),
        ("<thought>b</thought>", "b"),
        ("x <think>\nc\n</think> y", "c"),
        (" <think>  d  </think> ", "d")
    ])
    func testReasoningProcessParameterized(input: String, expected: String) {
        let result = input.reasoningProcess
        #expect(result == expected, "input: '\(input)'")
    }

    @Test(arguments: [
        ("<think>a</think>", ""),
        ("pre <think>mid</think> post", "pre  post"),
        (" <think>only</think> ", "")
    ])
    func testReasoningRemovedParameterized(input: String, expected: String) {
        let result = input.reasoningRemoved
        #expect(result == expected, "input: '\(input)'")
    }

    // MARK: - parseChartNumericValue

    @Test func testParseChartNumericValuePlainNumber() {
        #expect("42".parseChartNumericValue() == 42)
        #expect("3.14".parseChartNumericValue() == 3.14)
    }

    @Test func testParseChartNumericValueWithCommas() {
        #expect("1,234.56".parseChartNumericValue() == 1234.56)
        #expect("1, 234".parseChartNumericValue() == 1234)
    }

    @Test func testParseChartNumericValueWithPercent() {
        #expect("75%".parseChartNumericValue() == 75)
    }

    @Test func testParseChartNumericValueInvalidReturnsNil() {
        #expect("abc".parseChartNumericValue() == nil)
        #expect("".parseChartNumericValue() == nil)
    }
}
