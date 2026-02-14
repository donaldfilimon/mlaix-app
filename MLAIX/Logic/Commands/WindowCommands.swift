//
//  WindowCommands.swift
//  MLAI
//
//  Created by Bean John on 10/11/24.
//

import AppKit
import SwiftUI

@MainActor
public class WindowCommands {

	static var commands: some Commands {
		Group {
			CommandGroup(after: CommandGroupPlacement.windowArrangement) {
				Button {
					openNewMainWindow()
				} label: {
					Text("New Window")
				}
				.keyboardShortcut("n", modifiers: [.command, .shift])
				Button {
					NSApp.arrangeInFront(nil)
				} label: {
					Text("Bring All to Front")
				}
				Button {
					for window in NSApplication.shared.windows where window.isKeyWindow {
						window.toggleFullScreen(nil)
						break
					}
				} label: {
					Text("Enter Full Screen")
				}
				.keyboardShortcut("f", modifiers: [.control, .command])
			}
			openToolWindowsMenu
		}
	}

	/// Opens a new main (conversation) window; any open window’s observer calls openWindow(id: "newMain", value: UUID()).
	private static func openNewMainWindow() {
		NavigationState.shared.openNewMainWindowRequested = true
	}
}

// MARK: - Open Tool Windows

extension WindowCommands {

	private static var openToolWindowsMenu: some Commands {
		CommandGroup(after: .windowArrangement) {
			Menu {
				Button {
					NavigationState.shared.showToolboxRequested = true
				} label: {
					Text("Toolbox")
				}
				.keyboardShortcut("t", modifiers: .command)
				Divider()
				Button {
					NavigationState.shared.windowToOpen = "dashboard"
				} label: {
					Text("Dashboard")
				}
				Button {
					NavigationState.shared.windowToOpen = "detector"
				} label: {
					Text("Detector")
				}
				Button {
					NavigationState.shared.windowToOpen = "diagrammer"
				} label: {
					Text("Diagrammer")
				}
				Button {
					NavigationState.shared.windowToOpen = "slideStudio"
				} label: {
					Text("Slide Studio")
				}
				Button {
					NavigationState.shared.windowToOpen = "nodeEditor"
				} label: {
					Text("Node Editor")
				}
				Divider()
				Button {
					NavigationState.shared.windowToOpen = "memory"
				} label: {
					Text("Memory")
				}
				Button {
					NavigationState.shared.windowToOpen = "models"
				} label: {
					Text("Models")
				}
				Divider()
				Button {
					NavigationState.shared.showKeyboardShortcutsRequested = true
				} label: {
					Text("Keyboard Shortcuts")
				}
				.keyboardShortcut("k", modifiers: [.command, .shift])
			} label: {
				Text("Open")
			}
		}
	}
}
