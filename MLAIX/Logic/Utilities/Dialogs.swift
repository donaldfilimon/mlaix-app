//
//  Dialogs.swift
//  MLAI
//
//  Created by Bean John on 10/4/24.
//

import AppKit
import Foundation

@MainActor
public class Dialogs {

	/// Shows an alert with a single OK button.
	public static func showOK(
		title: String,
		message: String? = nil
	) {
		let alert = NSAlert()
		alert.messageText = title
		if let message = message {
			alert.informativeText = message
		}
		alert.addButton(withTitle: String(localized: "OK"))
		alert.alertStyle = .informational
		alert.runModal()
	}

	/// Function to show an alert (same as showOK; kept for compatibility).
	public static func showAlert(
		title: String,
		message: String? = nil
	) {
		showOK(title: title, message: message)
	}
	
	/// Shows a confirmation modal with Yes/No. Returns true if user chose Yes.
	public static func showConfirmation(
		title: String,
		message: String? = nil,
		ifConfirmed: @escaping () -> Void = {}
	) -> Bool {
		let alert = NSAlert()
		alert.messageText = title
		if let message = message {
			alert.informativeText = message
		}
		alert.addButton(withTitle: String(localized: "Yes"))
		alert.addButton(withTitle: String(localized: "No"))
		alert.alertStyle = .warning
		let result = alert.runModal() == .alertFirstButtonReturn
		if result { ifConfirmed() }
		return result
	}
	
	/// Function to show a dichotomy modal
	public static func dichotomy(
		title: String,
		message: String? = nil,
		option1: String,
		option2: String,
        ifOption1: @escaping () -> Void = {},
        ifOption2: @escaping () -> Void = {}
	) -> Bool {
		// Define alert
		let alert: NSAlert = NSAlert()
        alert.messageText = title
		if let message = message {
			alert.informativeText = message
		}
		alert.addButton(withTitle: option1)
		alert.addButton(withTitle: option2)
		// Run modal
		let result: Bool = alert.runModal() == .alertFirstButtonReturn
		if result {
			ifOption1()
		} else {
			ifOption2()
		}
		return result
	}
	
	/// Function to post low RAM warning
	public static func lowUnifiedMemoryWarning() {
		if InferenceSettings.lowUnifiedMemory {
			Self.showAlert(
				title: "Low Unified Memory",
				message: "Your system has only \(InferenceSettings.unifiedMemorySize) GB of RAM, which may not be sufficient for running an LLM. \nPlease save progress in all open apps, and close memory hogging applications in case a system crash occurs."
			)
		}
	}
	
}
