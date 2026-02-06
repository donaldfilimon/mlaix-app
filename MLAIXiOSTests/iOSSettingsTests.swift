//
//  iOSSettingsTests.swift
//  MLAIXiOSTests
//

import Foundation
import Testing
import MLAIXShared
@testable import MLAIXiOS

@MainActor
struct iOSSettingsTests {

    @Test func testHasConfiguredAPIFalseWhenEmpty() async {
        let settings = SharedAPIConfig.shared
        settings.apiBaseURL = nil
        settings.apiKey = nil
        #expect(!settings.hasConfiguredAPI)
    }

    @Test func testHasConfiguredAPIFalseWhenOnlyURL() async {
        let settings = SharedAPIConfig.shared
        settings.apiBaseURL = URL(string: "https://api.example.com")
        settings.apiKey = nil
        #expect(!settings.hasConfiguredAPI)
    }

    @Test func testHasConfiguredAPIFalseWhenOnlyKey() async {
        let settings = SharedAPIConfig.shared
        settings.apiBaseURL = nil
        settings.apiKey = "sk-xxx"
        #expect(!settings.hasConfiguredAPI)
    }

    @Test func testHasConfiguredAPITrueWhenBothSet() async {
        let settings = SharedAPIConfig.shared
        settings.apiBaseURL = URL(string: "https://api.example.com")
        settings.apiKey = "sk-xxx"
        #expect(settings.hasConfiguredAPI)
    }

    @Test func testModelDefaultsToGpt4oMini() async {
        let settings = SharedAPIConfig.shared
        settings.model = nil
        #expect(settings.model == "gpt-4o-mini")
    }
}
