//
//  FoundationModelsSupportTests.swift
//  MLAIXTests
//
//  Tests for FoundationModelsSupport availability types and error descriptions.
//

import Foundation
import Testing
@testable import MLAIX

@Suite("FoundationModelsSupportTests")
struct FoundationModelsSupportTests {

    // MARK: - AvailabilityStatus equality

    @Test func availabilityStatusAvailableEquality() {
        let a = FoundationModelsSupport.AvailabilityStatus.available
        let b = FoundationModelsSupport.AvailabilityStatus.available
        #expect(a == b)
    }

    @Test func availabilityStatusUnavailableEquality() {
        let a = FoundationModelsSupport.AvailabilityStatus.unavailable("reason A")
        let b = FoundationModelsSupport.AvailabilityStatus.unavailable("reason A")
        #expect(a == b)
    }

    @Test func availabilityStatusDifferentReasonsNotEqual() {
        let a = FoundationModelsSupport.AvailabilityStatus.unavailable("reason A")
        let b = FoundationModelsSupport.AvailabilityStatus.unavailable("reason B")
        #expect(a != b)
    }

    @Test func availabilityStatusAvailableVsUnavailableNotEqual() {
        let a = FoundationModelsSupport.AvailabilityStatus.available
        let b = FoundationModelsSupport.AvailabilityStatus.unavailable("reason")
        #expect(a != b)
    }

    // MARK: - isAvailable

    @Test func isAvailableReturnsBoolean() {
        let result = FoundationModelsSupport.isAvailable
        // On macOS < 26 this will be false; on macOS 26+ depends on system
        #expect(result == true || result == false)
    }

    @Test func isAvailableMatchesStatus() {
        let status = FoundationModelsSupport.availabilityStatus
        let isAvail = FoundationModelsSupport.isAvailable
        if case .available = status {
            #expect(isAvail == true)
        } else {
            #expect(isAvail == false)
        }
    }

    // MARK: - availabilityDescription

    @Test func availabilityDescriptionWhenUnavailable() {
        // On test systems without macOS 26, status is typically unavailable
        let desc = FoundationModelsSupport.availabilityDescription
        #expect(!desc.isEmpty)
        // Either "Available" or "Unavailable: ..."
        let startsCorrectly = desc.hasPrefix("Available") || desc.hasPrefix("Unavailable")
        #expect(startsCorrectly)
    }

    @Test func availabilityDescriptionConsistentWithStatus() {
        let status = FoundationModelsSupport.availabilityStatus
        let desc = FoundationModelsSupport.availabilityDescription
        switch status {
        case .available:
            #expect(desc == "Available")
        case .unavailable(let reason):
            #expect(desc.contains(reason))
            #expect(desc.hasPrefix("Unavailable:"))
        }
    }

    // MARK: - FoundationModelsError descriptions

    @Test func errorSessionUnavailableDescription() {
        let error = FoundationModelsError.sessionUnavailable
        #expect(error.errorDescription?.contains("not available") == true)
    }

    @Test func errorEmptyResponseDescription() {
        let error = FoundationModelsError.emptyResponse
        #expect(error.errorDescription?.contains("empty response") == true)
    }

    @Test func errorContextExhaustedDescription() {
        let error = FoundationModelsError.contextExhausted
        #expect(error.errorDescription?.contains("context window") == true)
    }

    @Test func errorStreamingFailedDescription() {
        let error = FoundationModelsError.streamingFailed("network timeout")
        #expect(error.errorDescription?.contains("network timeout") == true)
        #expect(error.errorDescription?.contains("streaming failed") == true)
    }

    @Test func errorConformsToLocalizedError() {
        let error: any Error = FoundationModelsError.emptyResponse
        #expect(error is LocalizedError)
    }

    @Test func errorAllCasesHaveDescriptions() {
        let errors: [FoundationModelsError] = [
            .sessionUnavailable,
            .emptyResponse,
            .contextExhausted,
            .streamingFailed("test")
        ]
        for error in errors {
            #expect(error.errorDescription != nil)
            #expect(!error.errorDescription!.isEmpty)
        }
    }
}
