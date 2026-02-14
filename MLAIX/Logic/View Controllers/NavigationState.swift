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
	/// Show toolbox sheet
	public var showToolboxRequested: Bool = false
	/// Tool sheet to present (replaces individual window scenes)
	public var activeToolSheet: ToolDestination? = nil
	/// Trigger to show script testing window
	public var showScriptTestingRequested: Bool = false
	/// Trigger to show keyboard shortcuts window
	public var showKeyboardShortcutsRequested: Bool = false
	/// Trigger to open new main window
	public var openNewMainWindowRequested: Bool = false
	/// Window to open (for dashboard etc.)
	public var windowToOpen: String? = nil

	private init() {}
}

// MARK: - Tool Destinations

/// Identifies a tool that can be opened as a sheet from the main window.
public enum ToolDestination: String, Identifiable, CaseIterable, Sendable {
	case dashboard
	case detector
	case diagrammer
	case slideStudio
	case nodeEditor
	case memory
	case models
	case keyboardShortcuts
	#if DEBUG
	case scriptTesting
	#endif

	public var id: String { rawValue }

	public var title: String {
		switch self {
		case .dashboard: return String(localized: "Dashboard")
		case .detector: return String(localized: "Detector")
		case .diagrammer: return String(localized: "Diagrammer")
		case .slideStudio: return String(localized: "Slide Studio")
		case .nodeEditor: return String(localized: "Node Editor")
		case .memory: return String(localized: "Memory")
		case .models: return String(localized: "Models")
		case .keyboardShortcuts: return String(localized: "Keyboard Shortcuts")
		#if DEBUG
		case .scriptTesting: return String(localized: "Script Testing")
		#endif
		}
	}
}
