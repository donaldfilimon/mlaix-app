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
        #expect(BackendAutoConfig.BackendAvailability.RecommendedBackend.mlx.rawValue == "mlx")
        #expect(BackendAutoConfig.BackendAvailability.RecommendedBackend.none.rawValue == "none")
    }

    @Test func testBackendAvailabilityInit() {
        let avail = BackendAutoConfig.BackendAvailability(
            local: true,
            remote: false,
            foundationModels: false,
            mlx: false,
            recommendedBackend: .local,
            canAutoConnect: true,
            suggestedRemoteEndpoint: nil
        )
        #expect(avail.local == true)
        #expect(avail.remote == false)
        #expect(avail.foundationModels == false)
        #expect(avail.mlx == false)
        #expect(avail.recommendedBackend == .local)
        #expect(avail.canAutoConnect == true)
    }

    // MARK: - Phase 2: All RecommendedBackend cases

    @Test func testAllRecommendedBackendCasesExist() {
        // Ensure all five cases compile and have correct raw values
        let cases: [BackendAutoConfig.BackendAvailability.RecommendedBackend] = [
            .local, .remote, .foundationModels, .mlx, .none
        ]
        #expect(cases.count == 5)
    }

    @Test func testRecommendedBackendRoundtripFromRawValue() {
        let rawValues = ["local", "remote", "foundationModels", "mlx", "none"]
        for raw in rawValues {
            let backend = BackendAutoConfig.BackendAvailability.RecommendedBackend(rawValue: raw)
            #expect(backend != nil)
            #expect(backend?.rawValue == raw)
        }
    }

    @Test func testRecommendedBackendInvalidRawValue() {
        let backend = BackendAutoConfig.BackendAvailability.RecommendedBackend(rawValue: "invalid")
        #expect(backend == nil)
    }

    // MARK: - MLX field in BackendAvailability

    @Test func testBackendAvailabilityMLXFieldTrue() {
        let avail = BackendAutoConfig.BackendAvailability(
            local: false,
            remote: false,
            foundationModels: false,
            mlx: true,
            recommendedBackend: .mlx,
            canAutoConnect: true,
            suggestedRemoteEndpoint: nil
        )
        #expect(avail.mlx == true)
        #expect(avail.recommendedBackend == BackendAutoConfig.BackendAvailability.RecommendedBackend.mlx)
    }

    @Test func testBackendAvailabilityMLXFieldFalse() {
        let avail = BackendAutoConfig.BackendAvailability(
            local: false,
            remote: false,
            foundationModels: false,
            mlx: false,
            recommendedBackend: .none,
            canAutoConnect: false,
            suggestedRemoteEndpoint: nil
        )
        #expect(avail.mlx == false)
    }

    // MARK: - Backend combinations

    @Test func testAllBackendsAvailable() {
        let avail = BackendAutoConfig.BackendAvailability(
            local: true,
            remote: true,
            foundationModels: true,
            mlx: true,
            recommendedBackend: .foundationModels,
            canAutoConnect: true,
            suggestedRemoteEndpoint: nil
        )
        #expect(avail.local == true)
        #expect(avail.remote == true)
        #expect(avail.foundationModels == true)
        #expect(avail.mlx == true)
        #expect(avail.canAutoConnect == true)
    }

    @Test func testNoBackendsAvailable() {
        let avail = BackendAutoConfig.BackendAvailability(
            local: false,
            remote: false,
            foundationModels: false,
            mlx: false,
            recommendedBackend: .none,
            canAutoConnect: false,
            suggestedRemoteEndpoint: nil
        )
        #expect(avail.local == false)
        #expect(avail.remote == false)
        #expect(avail.foundationModels == false)
        #expect(avail.mlx == false)
        #expect(avail.canAutoConnect == false)
        #expect(avail.recommendedBackend == .none)
    }

    @Test func testOnlyFoundationModelsAvailable() {
        let avail = BackendAutoConfig.BackendAvailability(
            local: false,
            remote: false,
            foundationModels: true,
            mlx: false,
            recommendedBackend: .foundationModels,
            canAutoConnect: true,
            suggestedRemoteEndpoint: nil
        )
        #expect(avail.foundationModels == true)
        #expect(avail.recommendedBackend == .foundationModels)
    }

    @Test func testOnlyRemoteAvailable() {
        let avail = BackendAutoConfig.BackendAvailability(
            local: false,
            remote: true,
            foundationModels: false,
            mlx: false,
            recommendedBackend: .remote,
            canAutoConnect: true,
            suggestedRemoteEndpoint: nil
        )
        #expect(avail.remote == true)
        #expect(avail.recommendedBackend == .remote)
    }

    @Test func testOnlyLocalAvailable() {
        let avail = BackendAutoConfig.BackendAvailability(
            local: true,
            remote: false,
            foundationModels: false,
            mlx: false,
            recommendedBackend: .local,
            canAutoConnect: true,
            suggestedRemoteEndpoint: nil
        )
        #expect(avail.local == true)
        #expect(avail.recommendedBackend == .local)
    }

    @Test func testOnlyMLXAvailable() {
        let avail = BackendAutoConfig.BackendAvailability(
            local: false,
            remote: false,
            foundationModels: false,
            mlx: true,
            recommendedBackend: .mlx,
            canAutoConnect: true,
            suggestedRemoteEndpoint: nil
        )
        #expect(avail.mlx == true)
        #expect(avail.recommendedBackend == BackendAutoConfig.BackendAvailability.RecommendedBackend.mlx)
    }

    @Test func testBackendAvailabilityIsSendable() {
        let avail = BackendAutoConfig.BackendAvailability(
            local: true,
            remote: false,
            foundationModels: false,
            mlx: true,
            recommendedBackend: .local,
            canAutoConnect: true,
            suggestedRemoteEndpoint: nil
        )
        let check: @Sendable () -> Bool = { avail.local }
        #expect(check() == true)
    }
}
