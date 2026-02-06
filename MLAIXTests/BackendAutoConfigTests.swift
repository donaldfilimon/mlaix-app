//
//  BackendAutoConfigTests.swift
//  MLAIXTests
//
//  Tests for BackendAutoConfig types.
//

import Foundation
import Testing
@testable import MLAIX

struct BackendAutoConfigTests {

    @Test func testRecommendedBackendRawValues() {
        #expect(BackendAutoConfig.BackendAvailability.RecommendedBackend.local.rawValue == "local")
        #expect(BackendAutoConfig.BackendAvailability.RecommendedBackend.remote.rawValue == "remote")
        #expect(BackendAutoConfig.BackendAvailability.RecommendedBackend.foundationModels.rawValue == "foundationModels")
        #expect(BackendAutoConfig.BackendAvailability.RecommendedBackend.none.rawValue == "none")
    }

    @Test func testBackendAvailabilityInit() {
        let avail = BackendAutoConfig.BackendAvailability(
            local: true,
            remote: false,
            foundationModels: false,
            recommendedBackend: .local,
            canAutoConnect: true
        )
        #expect(avail.local == true)
        #expect(avail.remote == false)
        #expect(avail.foundationModels == false)
        #expect(avail.recommendedBackend == .local)
        #expect(avail.canAutoConnect == true)
    }
}
