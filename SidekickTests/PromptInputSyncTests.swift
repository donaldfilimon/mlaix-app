//
//  PromptInputSyncTests.swift
//  MLAITests
//
//  Regression tests for prompt text and cursor synchronization.
//

import AppKit
import SwiftUI
import Testing
@testable import MLAI

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
        let field = makeField(box: box)
        let coordinator = field.makeCoordinator()
        let textView = NSTextView(frame: .zero)

        textView.string = "hello world"
        textView.setSelectedRange(NSRange(location: 11, length: 0))

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

        let field = makeField(box: box)
        let coordinator = field.makeCoordinator()
        let textView = NSTextView(frame: .zero)

        coordinator.suppressTextDidChange = true
        textView.string = "new value"
        textView.setSelectedRange(NSRange(location: 9, length: 0))

        coordinator.textDidChange(
            Notification(name: NSText.didChangeNotification, object: textView)
        )

        #expect(box.text == "seed")
        #expect(box.insertionPoint == 4)
        #expect(coordinator.suppressTextDidChange == false)
    }

    @Test @MainActor
    func textDidChangeIgnoresMarkedTextComposition() {
        let box = PromptInputBindingBox()
        box.text = "existing"
        box.insertionPoint = 8

        let field = makeField(box: box)
        let coordinator = field.makeCoordinator()
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
    func selectionChangePropagatesCursorMovement() {
        let box = PromptInputBindingBox()
        let field = makeField(box: box)
        let coordinator = field.makeCoordinator()
        let textView = NSTextView(frame: .zero)

        textView.string = "abcdef"
        textView.setSelectedRange(NSRange(location: 5, length: 0))

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

        let field = makeField(box: box)
        let coordinator = field.makeCoordinator()
        let textView = NSTextView(frame: .zero)

        coordinator.suppressSelectionDidChange = true
        textView.string = "0123456789"
        textView.setSelectedRange(NSRange(location: 9, length: 0))

        coordinator.textViewDidChangeSelection(
            Notification(name: NSTextView.didChangeSelectionNotification, object: textView)
        )

        #expect(box.insertionPoint == 2)
        #expect(coordinator.suppressSelectionDidChange == false)
    }
}
