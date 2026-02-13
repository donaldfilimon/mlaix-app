//
//  StartupMetrics.swift
//  MLAI
//
//  Created by John Bean on 11/12/25.
//

import Foundation
import OSLog

enum StartupMetrics {

    private static let subsystem: String = Bundle.main.bundleIdentifier ?? "com.donaldfilimon.mlai"
    static let signposter = OSSignposter(subsystem: subsystem, category: "Startup")

    @discardableResult
    static func beginInterval(_ name: StaticString) -> OSSignpostIntervalState {
        signposter.beginInterval(name)
    }

    static func endInterval(_ name: StaticString, _ state: OSSignpostIntervalState) {
        signposter.endInterval(name, state)
    }

    static func event(_ name: StaticString) {
        signposter.emitEvent(name)
    }

    static func withInterval<T>(_ name: StaticString, _ body: () async throws -> T) async rethrows -> T {
        let state = beginInterval(name)
        defer { endInterval(name, state) }
        return try await body()
    }
}
