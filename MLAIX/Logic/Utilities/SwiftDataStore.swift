//
//  SwiftDataStore.swift
//  MLAIX
//
//  Provides app-wide access to the shared SwiftData container and main context
//  so managers can read/write SwiftData after JSON migration.
//

import Foundation
import SwiftData

/// Shared SwiftData container and main-actor context for use by managers and views.
/// Set in app init after migration; views should prefer `@Environment(\.modelContainer)`.
public enum SwiftDataStore {

    /// Container for the main app store. Set once at launch.
    public static nonisolated(unsafe) var sharedContainer: ModelContainer?

    /// Main-actor context used for migration and by managers when using SwiftData.
    /// Use this for sync fetch/save from @MainActor singletons.
    public static nonisolated(unsafe) var mainContext: ModelContext?
}
