//
//  TestUtilities.swift
//  MLAIXTests
//
//  Shared helpers for unit tests.
//

import Foundation
@testable import MLAIX

enum TestUtilities {

    // MARK: - Timing

    /// Wait duration after triggering a debounced save (ConversationManager uses 350ms).
    /// Use this in persistence tests so the debounce has time to flush.
    static let saveDebounceWait: Duration = .milliseconds(500)

    /// Poll interval when waiting for async conditions (e.g. manager load).
    static let pollInterval: Duration = .milliseconds(50)

    /// Waits for the given duration. Prefer named constants (e.g. saveDebounceWait) in tests.
    static func wait(_ duration: Duration) async throws {
        try await Task.sleep(for: duration)
    }

    // MARK: - Temp Directory

    /// Creates a unique temporary directory for test data. Caller is responsible for cleanup.
    @MainActor
    static func makeTempContainerUrl() throws -> URL {
        let base = FileManager.default.temporaryDirectory
            .appendingPathComponent("MLAIX-Tests")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(
            at: base,
            withIntermediateDirectories: true
        )
        return base
    }

    /// Runs a closure with a temporary directory and removes it after the block (best-effort).
    @MainActor
    static func withTempDirectory<T>(_ body: (URL) async throws -> T) async throws -> T {
        let url = try makeTempContainerUrl()
        defer {
            try? FileManager.default.removeItem(at: url)
        }
        return try await body(url)
    }

    // MARK: - Managers

    /// Waits until the conversation manager has finished loading.
    @MainActor
    static func waitForLoaded(_ manager: ConversationManager) async {
        while !manager.isLoaded {
            try? await Task.sleep(for: pollInterval)
        }
    }

    /// Waits up to a limit for a condition to become true; returns whether it succeeded.
    @MainActor
    static func waitUntil(
        timeout: Duration = .seconds(5),
        interval: Duration = pollInterval,
        condition: () async -> Bool
    ) async -> Bool {
        let clock = ContinuousClock()
        let start = clock.now
        while clock.now - start < timeout {
            if await condition() { return true }
            try? await Task.sleep(for: interval)
        }
        return false
    }
}
