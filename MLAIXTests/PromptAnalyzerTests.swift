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
}
