//
//  DockMenuCommands.swift
//  MLAI
//
//  Builds the dock menu (right-click app icon in dock). Used by AppDelegate.
//

import AppKit
import Foundation

public enum DockMenuCommands {

	/// Builds the dock menu. Call from AppDelegate.applicationDockMenu.
	public static func makeDockMenu(target: AnyObject) -> NSMenu {
		let menu = NSMenu()
		let newConv = NSMenuItem(
			title: String(localized: "New Conversation"),
			action: #selector(AppDelegate.dockNewConversation(_:)),
			keyEquivalent: ""
		)
		newConv.target = target
		menu.addItem(newConv)
		let toolbox = NSMenuItem(
			title: String(localized: "Toolbox"),
			action: #selector(AppDelegate.dockShowToolbox(_:)),
			keyEquivalent: ""
		)
		toolbox.target = target
		menu.addItem(toolbox)
		menu.addItem(NSMenuItem.separator())
		let settings = NSMenuItem(
			title: String(localized: "Settings…"),
			action: #selector(AppDelegate.dockOpenSettings(_:)),
			keyEquivalent: ","
		)
		settings.target = target
		menu.addItem(settings)
		return menu
	}
}
