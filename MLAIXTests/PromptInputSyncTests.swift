//
//  PromptInputSyncTests.swift
//  MLAITests
//
//  Regression tests for prompt text and cursor synchronization.
//

import AppKit
import SwiftUI
import Testing
@testable import MLAIX

@MainActor
private final class PromptInputBindingBox {
    var text: String = ""
    var insertionPoint: Int = 0
}

@MainActor
private final class MarkedTextTextView: NSTextView {
    override func hasMarkedText() -> Bool {
        true
    }
}

@MainActor
private final class OutOfBoundsSelectionTextView: NSTextView {
    var forcedRange: NSRange = NSRange(location: 0, length: 0)

    override var selectedRange: NSRange {
        get { forcedRange }
        set { forcedRange = newValue }
    }
}

@MainActor
private func makeCoordinator(
    box: PromptInputBindingBox
) -> MultilineTextField.Coordinator {
    makeField(box: box).makeCoordinator()
}

@MainActor
private func makeTextView(
    text: String = "",
    cursor: Int = 0
) -> NSTextView {
    let textView = NSTextView(frame: .zero)
    textView.string = text
    textView.setSelectedRange(NSRange(location: cursor, length: 0))
    return textView
}

@MainActor
private func makeField(
    box: PromptInputBindingBox
) -> MultilineTextField {
    MultilineTextField(
        text: Binding(
            get: { box.text },
            set: { box.text = $0 }
        ),
        insertionPoint: Binding(
            get: { box.insertionPoint },
            set: { box.insertionPoint = $0 }
        ),
        prompt: "Enter a message."
    )
}

struct PromptInputSyncTests {

    @Test @MainActor
    func textDidChangePropagatesUserEdits() {
        let box = PromptInputBindingBox()
        let coordinator = makeCoordinator(box: box)
        let textView = makeTextView(text: "hello world", cursor: 11)

        coordinator.textDidChange(
            Notification(name: NSText.didChangeNotification, object: textView)
        )

        #expect(box.text == "hello world")
        #expect(box.insertionPoint == 11)
        #expect(coordinator.lastTextFromView == "hello world")
        #expect(coordinator.lastSelectionFromView == 11)
    }

    @Test @MainActor
    func textDidChangeHonorsSuppressionFlagExactlyOnce() {
        let box = PromptInputBindingBox()
        box.text = "seed"
        box.insertionPoint = 4

        let coordinator = makeCoordinator(box: box)
        let textView = makeTextView(text: "new value", cursor: 9)

        coordinator.lastTextFromView = "new value"
        coordinator.lastSelectionFromView = 9
        coordinator.suppressTextDidChange = true

        coordinator.textDidChange(
            Notification(name: NSText.didChangeNotification, object: textView)
        )

        #expect(box.text == "seed")
        #expect(box.insertionPoint == 4)
        #expect(coordinator.suppressTextDidChange == false)
    }

    @Test @MainActor
    func textDidChangeDoesNotDropRealEditsWhenSuppressionIsStale() {
        let box = PromptInputBindingBox()
        box.text = "seed"
        box.insertionPoint = 4

        let coordinator = makeCoordinator(box: box)
        let textView = makeTextView(text: "typed", cursor: 5)

        coordinator.lastTextFromView = "seed"
        coordinator.suppressTextDidChange = true

        coordinator.textDidChange(
            Notification(name: NSText.didChangeNotification, object: textView)
        )

        #expect(box.text == "typed")
        #expect(box.insertionPoint == 5)
        #expect(coordinator.suppressTextDidChange == false)
    }

    @Test @MainActor
    func textDidChangeIgnoresMarkedTextComposition() {
        let box = PromptInputBindingBox()
        box.text = "existing"
        box.insertionPoint = 8

        let coordinator = makeCoordinator(box: box)
        let textView = MarkedTextTextView(frame: .zero)

        textView.string = "intermediate-ime-text"
        textView.setSelectedRange(NSRange(location: 3, length: 0))

        coordinator.textDidChange(
            Notification(name: NSText.didChangeNotification, object: textView)
        )

        #expect(box.text == "existing")
        #expect(box.insertionPoint == 8)
    }

    @Test @MainActor
    func textDidChangeClampsSelectionToTextBounds() {
        let box = PromptInputBindingBox()
        let coordinator = makeCoordinator(box: box)
        let textView = OutOfBoundsSelectionTextView(frame: .zero)
        textView.string = "abc"
        textView.selectedRange = NSRange(location: 999, length: 0)

        coordinator.textDidChange(
            Notification(name: NSText.didChangeNotification, object: textView)
        )

        #expect(box.text == "abc")
        #expect(box.insertionPoint == 3)
        #expect(coordinator.lastSelectionFromView == 3)
    }

    @Test @MainActor
    func selectionChangePropagatesCursorMovement() {
        let box = PromptInputBindingBox()
        let coordinator = makeCoordinator(box: box)
        let textView = makeTextView(text: "abcdef", cursor: 5)

        coordinator.textViewDidChangeSelection(
            Notification(name: NSTextView.didChangeSelectionNotification, object: textView)
        )

        #expect(box.insertionPoint == 5)
        #expect(coordinator.lastSelectionFromView == 5)
    }

    @Test @MainActor
    func selectionChangeHonorsSuppressionFlagExactlyOnce() {
        let box = PromptInputBindingBox()
        box.insertionPoint = 2

        let coordinator = makeCoordinator(box: box)
        let textView = makeTextView(text: "0123456789", cursor: 9)

        coordinator.lastSelectionFromView = 9
        coordinator.suppressSelectionDidChange = true

        coordinator.textViewDidChangeSelection(
            Notification(name: NSTextView.didChangeSelectionNotification, object: textView)
        )

        #expect(box.insertionPoint == 2)
        #expect(coordinator.suppressSelectionDidChange == false)
    }

    @Test @MainActor
    func selectionChangeDoesNotDropRealMovementWhenSuppressionIsStale() {
        let box = PromptInputBindingBox()
        box.insertionPoint = 2

        let coordinator = makeCoordinator(box: box)
        let textView = makeTextView(text: "0123456789", cursor: 7)

        coordinator.lastSelectionFromView = 2
        coordinator.suppressSelectionDidChange = true

        coordinator.textViewDidChangeSelection(
            Notification(name: NSTextView.didChangeSelectionNotification, object: textView)
        )

        #expect(box.insertionPoint == 7)
        #expect(coordinator.suppressSelectionDidChange == false)
    }

    @Test @MainActor
    func selectionChangeClampsSelectionToTextBounds() {
        let box = PromptInputBindingBox()
        let coordinator = makeCoordinator(box: box)
        let textView = OutOfBoundsSelectionTextView(frame: .zero)
        textView.string = "abcd"
        textView.selectedRange = NSRange(location: 123, length: 0)

        coordinator.textViewDidChangeSelection(
            Notification(name: NSTextView.didChangeSelectionNotification, object: textView)
        )

        #expect(box.insertionPoint == 4)
        #expect(coordinator.lastSelectionFromView == 4)
    }
}
