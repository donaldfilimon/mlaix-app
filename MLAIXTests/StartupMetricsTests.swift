//
//  StartupMetricsTests.swift
//  MLAIXTests
//
//  Tests for StartupMetrics signpost helpers.
//

import Foundation
import Testing
@testable import MLAIX

@Suite("StartupMetricsTests")
struct StartupMetricsTests {

    // MARK: - signposter access

    @Test func signposterExists() {
        let signposter = StartupMetrics.signposter
        // Just verify the signposter is accessible (non-nil value type)
        _ = signposter
    }

    // MARK: - withInterval

    @Test func withIntervalExecutesBodyAndReturnsResult() async throws {
        let result = await StartupMetrics.withInterval("TestInterval") {
            return 42
        }
        #expect(result == 42)
    }

    @Test func withIntervalExecutesBodyWithStringResult() async throws {
        let result = await StartupMetrics.withInterval("StringInterval") {
            return "hello"
        }
        #expect(result == "hello")
    }

    @Test func withIntervalPropagatesAsyncWork() async throws {
        let result = await StartupMetrics.withInterval("AsyncInterval") {
            try? await Task.sleep(for: .milliseconds(10))
            return true
        }
        #expect(result == true)
    }

    // MARK: - beginInterval / endInterval

    @Test func beginAndEndIntervalDoNotCrash() {
        let state = StartupMetrics.beginInterval("TestBeginEnd")
        StartupMetrics.endInterval("TestBeginEnd", state)
        // If we reach here, no crash occurred
    }

    @Test func multipleIntervalsDoNotCrash() {
        let state1 = StartupMetrics.beginInterval("Interval1")
        let state2 = StartupMetrics.beginInterval("Interval2")
        StartupMetrics.endInterval("Interval2", state2)
        StartupMetrics.endInterval("Interval1", state1)
    }

    // MARK: - event

    @Test func eventDoesNotCrash() {
        StartupMetrics.event("TestEvent")
        // If we reach here, no crash occurred
    }

    @Test func multipleEventsDoNotCrash() {
        StartupMetrics.event("Event1")
        StartupMetrics.event("Event2")
        StartupMetrics.event("Event3")
    }
}
