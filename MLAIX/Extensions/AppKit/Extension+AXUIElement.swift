//
//  Extension+AXUIElement.swift
//
//  Created by Aether on 02/01/2025.
//

import Cocoa
import ApplicationServices
import OSLog

// MARK: - Helper Function

/// Safely casts a `CFTypeRef` to a desired CoreFoundation type using `unsafeBitCast`.
/// - Parameters:
///   - value: The value to cast (must be a `CFTypeRef?`).
///   - type: The desired CF type.
/// - Returns: The casted value if the input is non-nil, otherwise `nil`.
private func castCF<U>(_ value: CFTypeRef?, to type: U.Type = U.self) -> U? {
    guard let value = value else { return nil }
    return unsafeBitCast(value, to: U.self)
}

public extension AXUIElement {
    /// Attempts to return the bounding rect of the insertion point (cursor) in the current text area.
    /// Fallback order: Caret Bounds → Caret Rect → Mouse Cursor Rect.
    /// - Returns: `cursorPositionResult` representing the bounding rectangle and type
    ///
    func resolveCursorPosition() -> CursorPositionResult? {
		// 1. Attempt to get caret bounds
		if let caretBounds = getCaretBounds() {
			return CursorPositionResult(
				type: .caret,
				bounds: caretBounds
			)
		}
		// 2. Attempt to get caret bounds with fallback
		if let caretBounds = fallbackGetCaretBounds() {
			return CursorPositionResult(
				type: .caretFallback,
				bounds: caretBounds
			)
		}
        // 3. Attempt to get caret rect
        if let caretRect = getCaretRect() {
            return CursorPositionResult(type: .rect, bounds: caretRect)
        }
        // 4. Fallback to mouse cursor position
        if let mouseRect = getMouseCursorRect() {
            return CursorPositionResult(type: .mouseCursor, bounds: mouseRect)
        }
        return nil
    }
    
    // MARK: - Primary Method: Caret Bounds
    
	/// Primary method to retrieve the bounding rect of the caret using `AXSelectedTextRange` and `AXBoundsForRange`.
	/// - Returns: The `CGRect` representing the caret's bounding rectangle, or `nil` if unavailable.
	private func getCaretBounds() -> CGRect? {
		// Attempt to get the current cursor position
		guard let cursorPosition = getCursorPosition() else {
			Logger(subsystem: Bundle.main.logSubsystem, category: "AXUIElement").debug("Cursor position not available")
			return nil
		}
		// Create a CFRange starting at the cursor position with a length of 1
		var cfRange: CFRange = .init(location: cursorPosition, length: 1)
		// Convert the CFRange into an AXValue which is needed for the AX API
		let axVal: AXValue? = AXValueCreate(.cfRange, &cfRange)
		// Declare a variable to hold the bounds received from the AX API
		var bounds: CFTypeRef?
		// If the AXValue creation failed, return nil
		guard let axVal = axVal else { return nil }
		// Use the AX API to copy the parameterized attribute value for the range
		AXUIElementCopyParameterizedAttributeValue(
			self,
			kAXBoundsForRangeParameterizedAttribute as CFString,
			axVal,
			&bounds
		)
		// Initialize a CGRect to store the final caret bounds; start with CGRect.zero
		var cursorRect: CGRect = .zero
		// If no bounds were retrieved, return nil
		guard let bounds = bounds else { return nil }
		// Extract the CGRect from the returned AXValue
		let boundsValue = unsafeBitCast(bounds, to: AXValue.self)
		AXValueGetValue(boundsValue, .cgRect, &cursorRect)
		// Return the computed caret bounds
		return cursorRect
	}
	
	/// Fallback method to retrieve the bounding rect of the caret using `AXSelectedTextRange` and `AXBoundsForRange`.
	/// - Returns: The `CGRect` representing the caret's bounding rectangle, or `nil` if unavailable.
	func fallbackGetCaretBounds() -> CGRect? {
		// Create a system-wide accessibility object
		let systemWideElement = AXUIElementCreateSystemWide()
		// Get the currently focused UI element
		var focusedElement: AnyObject?
		let focusedResult = AXUIElementCopyAttributeValue(
			systemWideElement,
			kAXFocusedUIElementAttribute as CFString,
			&focusedElement
		)
		guard focusedResult == .success, let focusedElement else {
			Logger(subsystem: Bundle.main.logSubsystem, category: "AXUIElement").debug("Failed to get focused element")
			return nil
		}
		let element = unsafeBitCast(focusedElement, to: AXUIElement.self)
		// Retrieve the 'kAXSelectedTextRangeAttribute' from the focused element
		var selectedTextRangeRef: AnyObject?
		let rangeResult = AXUIElementCopyAttributeValue(
			element,
			kAXSelectedTextRangeAttribute as CFString,
			&selectedTextRangeRef
		)
		guard rangeResult == .success else {
			Logger(subsystem: Bundle.main.logSubsystem, category: "AXUIElement").debug("Failed to get selected text range")
			return nil
		}
		guard let selectedTextRangeRef else {
			Logger(subsystem: Bundle.main.logSubsystem, category: "AXUIElement").debug("Failed to cast selected text range to AXValue")
			return nil
		}
		let selectedTextRange = unsafeDowncast(selectedTextRangeRef, to: AXValue.self)
		// The selectedTextRange is represented as a CFRange
		var range = CFRange()
		guard AXValueGetValue(selectedTextRange, .cfRange, &range) else {
			Logger(subsystem: Bundle.main.logSubsystem, category: "AXUIElement").debug("Failed to extract CFRange from selected text range")
			return nil
		}
		// Obtain the bounding rectangle for the given text range
		var caretBoundsRef: AnyObject?
		let boundsResult = AXUIElementCopyParameterizedAttributeValue(
			element,
			kAXBoundsForRangeParameterizedAttribute as CFString,
			selectedTextRange,
			&caretBoundsRef
		)
		guard boundsResult == .success else {
			Logger(subsystem: Bundle.main.logSubsystem, category: "AXUIElement").debug("Failed to get caret bounding rectangle")
			return nil
		}
		guard let caretBoundsRef else {
			Logger(subsystem: Bundle.main.logSubsystem, category: "AXUIElement").debug("Failed to cast caret bounds to AXValue")
			return nil
		}
		let caretBoundsValue = unsafeDowncast(caretBoundsRef, to: AXValue.self)
		var caretRect = CGRect.zero
		guard AXValueGetValue(caretBoundsValue, .cgRect, &caretRect) else {
			Logger(subsystem: Bundle.main.logSubsystem, category: "AXUIElement").debug("Failed to extract CGRect from caret value")
			return nil
		}
		// Return the rect of the caret
		return caretRect
	}
    
    // MARK: - Secondary Method: Caret Rect
    
    /// Secondary method to retrieve the caret's rect, especially useful when the caret is at the end of the text (caret has issues being accessed - will address later).
    /// Ensures that the bounds belong to a text-related element before returning (otherwise regular cursor fallback will never be triggered).
    /// - Returns: The `CGRect` representing the caret's rect, or `nil` if unavailable or invalid.
    private func getCaretRect() -> CGRect? {
        // Retrieve the AXRole attribute to verify the element type
        guard let role = getAttributeString(attribute: kAXRoleAttribute) else {
            return nil
        }
        // Define expected roles that are text-related
        let expectedRoles: Set<String> = ["AXTextField", "AXTextArea", "AXSearchField", "AXComboBox"]
        // Verify that the element's role is one of the expected text-related roles
        guard expectedRoles.contains(role) else {
            return nil
        }
        // Attempt to retrieve the AXFrame attribute
        let kAXFrameAttribute = "AXFrame"
        let kAXPositionAttribute = "AXPosition"
        let kAXFrameAttributeStr = kAXFrameAttribute as String
        var frameValue: CFTypeRef?
        let frameError = AXUIElementCopyAttributeValue(self, kAXFrameAttributeStr as CFString, &frameValue)
        
		if frameError == .success, let axFrame = castCF(frameValue, to: AXValue.self) {
			var frame = CGRect.zero
			if AXValueGetValue(axFrame, .cgRect, &frame) {
				return frame
			}
		}
        // Attempt to retrieve the AXPosition attribute as a fallback
        let kAXPositionAttributeStr = kAXPositionAttribute as String
        var positionValue: CFTypeRef?
        let positionError = AXUIElementCopyAttributeValue(self, kAXPositionAttributeStr as CFString, &positionValue)
		if positionError == .success, let axPosition = castCF(positionValue, to: AXValue.self) {
			var position = CGPoint.zero
			if AXValueGetValue(axPosition, .cgPoint, &position) {
				// Returning a CGRect with zero size at the caret's position
				return CGRect(origin: position, size: CGSize(width: 0, height: 0))
			}
		}
		return nil
    }
    
    // MARK: - Helper Method: Retrieve String Attributes
    
    /// Retrieves a string attribute from the AXUIElement.
    /// - Parameter attribute: The AX attribute to retrieve (e.g., kAXRoleAttribute).
    /// - Returns: The string value of the attribute, or `nil` if unavailable.
    private func getAttributeString(attribute: String) -> String? {var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(self, attribute as CFString, &value)
        guard error == .success else {
            return nil
        }
        // Use castCF to safely cast the value to CFString
        if let cfString = castCF(value, to: CFString.self) {
            let string = cfString as String
            return string
        } else {
            return nil
        }
    }
	
    // MARK: - Fallback Method: Mouse Cursor Position
    
    /// Fallback method to retrieve the mouse cursor's position as a `CGRect`.
    /// - Returns: A `CGRect` representing the mouse cursor's position, or `nil` if unavailable.
    private func getMouseCursorRect() -> CGRect? {
        // Get the current mouse location in screen coordinates
        let mouseLocation = NSEvent.mouseLocation
        // Find the screen that contains the mouse location
        guard let screen = NSScreen.screens.first(where: { NSPointInRect(mouseLocation, $0.frame) }) else {
            return nil
        }
        // Get the screen's height and origin
        let screenHeight = screen.frame.height
        // Adjust the Y coordinate relative to the screen's origin
        let adjustedY = screenHeight - mouseLocation.y
        // Create a CGRect at the mouse location with a default size
        // This represents a 1x1 point rectangle at the cursor's position
        let cursorRect = CGRect(origin: CGPoint(x: mouseLocation.x, y: adjustedY), size: CGSize(width: 1, height: 1))
        return cursorRect
    }
    
    // MARK: - Helper Methods
    
    /// Retrieves the integer offset of the insertion caret.
    /// - Returns: The cursor's integer position within the text, or `nil` if unavailable.
    private func getCursorPosition() -> Int? {
        let kAXSelectedTextRange = "AXSelectedTextRange"
        var rawValue: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(
            self,
            kAXSelectedTextRange as CFString,
            &rawValue
        )
		guard error == .success,
              let axRangeValue = castCF(rawValue, to: AXValue.self) else {
            return nil
        }
        var range = CFRange()
        if AXValueGetValue(axRangeValue, .cfRange, &range) {
            return range.location
        }
		Logger(subsystem: Bundle.main.logSubsystem, category: "AXUIElement").debug("Failed to get range value")
        return nil
    }
    
}
