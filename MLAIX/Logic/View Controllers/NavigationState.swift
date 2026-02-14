//
//  NavigationState.swift
//  MLAIX
//
//  Centralized navigation and action state, replacing NotificationCenter pub/sub.
//

import Foundation
import Observation

/// Centralized navigation and action state, replacing NotificationCenter pub/sub
@MainActor
@Observable
public final class NavigationState {
	/// Singleton instance
	public static let shared = NavigationState()

	/// Conversation to switch to
	public var switchToConversationId: UUID?
	/// Trigger to create a new conversation
	public var newConversationRequested: Bool = false
	/// Trigger to send current message
	public var sendMessageRequested: Bool = false
	/// Expert selected via command
	public var commandSelectedExpertId: UUID?
	/// Toggle canvas visibility
	public var toggleCanvasRequested: Bool = false
	/// Toggle functions
	public var toggleFunctionsRequested: Bool = false
	/// Toggle web search
	public var toggleWebSearchRequested: Bool = false
	/// System prompt changed
	public var systemPromptChanged: Bool = false
	/// Inference config changed
	public var inferenceConfigChanged: Bool = false
	/// Show keyboard shortcuts window
	public var showKeyboardShortcutsRequested: Bool = false
	/// Show toolbox sheet
	public var showToolboxRequested: Bool = false
	/// Open a window by id (e.g. "models", "dashboard"); observer should call openWindow and clear.
	public var windowToOpen: String?
	/// When true, observer should call openWindow(id: "newMain", value: UUID()) to open another main window.
	public var openNewMainWindowRequested: Bool = false
	/// Show script testing window (debug only)
	public var showScriptTestingRequested: Bool = false

	private init() {}
}
