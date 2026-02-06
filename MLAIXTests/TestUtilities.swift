//
//  TestUtilities.swift
//  MLAIXTests
//
//  Shared helpers for unit tests.
//

import Foundation
@testable import MLAIX

enum TestUtilities {

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

    /// Waits until the conversation manager has finished loading.
    @MainActor
    static func waitForLoaded(_ manager: ConversationManager) async {
        while !manager.isLoaded {
            try? await Task.sleep(for: .milliseconds(50))
        }
    }
}
