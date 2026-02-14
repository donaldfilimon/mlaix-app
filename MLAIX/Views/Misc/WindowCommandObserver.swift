//
//  WindowCommandObserver.swift
//  MLAIX
//
//  Observes NavigationState and opens windows / brings main window forward from any scene.
//

import AppKit
import SwiftUI

/// Modifier that reacts to NavigationState (windowToOpen, keyboard shortcuts, toolbox) so that
/// menu commands and dock actions work from any window, not only the main one.
struct WindowCommandObserver: ViewModifier {
    @Environment(\.openWindow) private var openWindow

    func body(content: Content) -> some View {
        content
            .onChange(of: NavigationState.shared.windowToOpen) { _, windowId in
                guard let id = windowId else { return }
                openWindow(id: id)
                NavigationState.shared.windowToOpen = nil
            }
            .onChange(of: NavigationState.shared.showKeyboardShortcutsRequested) { _, newValue in
                guard newValue else { return }
                openWindow(id: "keyboardShortcuts")
                NavigationState.shared.showKeyboardShortcutsRequested = false
            }
            .onChange(of: NavigationState.shared.showToolboxRequested) { _, newValue in
                guard newValue else { return }
                AppWindowManager.bringMainWindowToFront()
                // Toolbox sheet is shown by ConversationManagerView when it becomes visible
            }
            .onChange(of: NavigationState.shared.openNewMainWindowRequested) { _, newValue in
                guard newValue else { return }
                openWindow(id: "main")
                NavigationState.shared.openNewMainWindowRequested = false
            }
            #if DEBUG
            .onChange(of: NavigationState.shared.showScriptTestingRequested) { _, newValue in
                guard newValue else { return }
                openWindow(id: "scriptTesting")
                NavigationState.shared.showScriptTestingRequested = false
            }
            #endif
    }
}

extension View {
    /// Ensures Open-window and keyboard-shortcuts commands work when this view is the root of any window.
    func observeWindowCommands() -> some View {
        modifier(WindowCommandObserver())
    }
}

/// Helpers for multi-window behavior (identify main window, bring to front).
/// The app supports multiple main windows: Window > New Window (⌘⇧N) opens another conversation window.
@MainActor
enum AppWindowManager {
    /// Title used by the main conversation window so we can find it (often the app name).
    static let mainWindowTitle = "MLAIX"

    /// Brings the main (conversation) window to front and makes it key so the user lands there.
    static func bringMainWindowToFront() {
        NSApp.activate(ignoringOtherApps: true)
        guard let main = mainWindow else { return }
        main.makeKeyAndOrderFront(nil)
    }

    /// First key-capable window that looks like the main app window (by title).
    static var mainWindow: NSWindow? {
        NSApp.windows.first { win in
            win.canBecomeKey && (win.title == mainWindowTitle || win.title.isEmpty)
        }
    }
}
