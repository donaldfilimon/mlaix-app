//
//  DockMenuCommands.swift
//  MLAI
//
//  Created by Bean John on 10/5/24.
//

import AppKit
import Foundation
import OSLog

public class DockMenuCommands {
	private static let logger = Logger(subsystem: Bundle.main.logSubsystem, category: String(describing: DockMenuCommands.self))

	@objc public static func test(_ sender: NSMenuItem) {
		Self.logger.debug("Test button clicked")
	}
	
}
