//
//  Extension+Bundle.swift
//  Sidekick
//

import Foundation

extension Bundle {

    /// A subsystem string suitable for `OSLog.Logger`, with a fallback for when the app is run
    /// via SwiftPM (`swift run`) where `bundleIdentifier` may be nil.
    var logSubsystem: String {
        bundleIdentifier ?? "com.pattonium.Sidekick"
    }
}
