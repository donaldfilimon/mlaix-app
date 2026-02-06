//
//  MultilineTextEditor.swift
//  MLAI
//
//  Created by John Bean on 4/20/25.
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers
import OSLog

struct MultilineTextField: NSViewRepresentable {
    
    @Binding var text: String
    @Binding var insertionPoint: Int
    var shouldFocus: Bool = false
    let prompt: String
    var onImageDrop: ((URL) -> Void)?

    private func clampedCursor(_ cursor: Int, in value: String) -> Int {
        max(0, min(cursor, value.utf16.count))
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(
        context: Context
    ) -> PromptingScrollView {
        let scrollView = PromptingScrollView()
        let textView = PromptingTextView()
        textView.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        textView.delegate = context.coordinator
        textView.setPrompt(prompt)
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.heightTracksTextView = false
        textView.textContainerInset = NSSize(width: 2, height: 4)
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.usesAdaptiveColorMappingForDarkAppearance = true
        textView.isRichText = false
        textView.importsGraphics = false
        textView.textColor = .labelColor
        textView.typingAttributes[.foregroundColor] = NSColor.labelColor
        textView.insertionPointColor = NSColor.controlAccentColor
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        // Set min and max size for proper scrolling
        let font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        let lineHeight = font.ascender - font.descender + font.leading
        let minHeight = lineHeight + textView.textContainerInset.height * 2
        textView.minSize = NSSize(width: 0, height: minHeight)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.autoresizingMask = [.width]
        let initialText = text
        textView.string = initialText
        let safeInsertionPoint = clampedCursor(insertionPoint, in: initialText)
        textView.setSelectedRange(NSRange(location: safeInsertionPoint, length: 0))
        textView.onImageDrop = context.coordinator.onImageDrop
        // Register for drag types
        textView.registerForDraggedTypes([
            .fileURL,
            .png,
            .tiff,
            .URL
        ])
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false
        scrollView.setContentHuggingPriority(.required, for: .vertical)
        scrollView.setContentCompressionResistancePriority(.required, for: .vertical)
        return scrollView
    }
    
    func updateNSView(
        _ nsView: PromptingScrollView,
        context: Context
    ) {
        guard let textView = nsView.documentView as? PromptingTextView else { return }
        let coordinator = context.coordinator
        coordinator.parent = self
        let isFirstResponder = textView.window?.firstResponder == textView
        let hasMarkedText = textView.hasMarkedText()
        let desiredTextColor: NSColor = .labelColor
        let desiredInsertionColor: NSColor = .controlAccentColor
        let clampedInsertionPoint = clampedCursor(insertionPoint, in: text)
        if insertionPoint != clampedInsertionPoint {
            Task { @MainActor in
                self.insertionPoint = clampedInsertionPoint
            }
        }
        if textView.textColor != desiredTextColor {
            textView.textColor = desiredTextColor
        }
        if textView.insertionPointColor != desiredInsertionColor {
            textView.insertionPointColor = desiredInsertionColor
        }
        if (textView.typingAttributes[.foregroundColor] as? NSColor) != desiredTextColor {
            var attributes = textView.typingAttributes
            attributes[.foregroundColor] = desiredTextColor
            textView.typingAttributes = attributes
        }
        
        // Save current scroll position
        let currentScrollPosition = nsView.contentView.bounds.origin
        
        // Update the callback
        textView.onImageDrop = context.coordinator.onImageDrop
        
        // Enable scroll position preservation during programmatic updates
        textView.shouldPreserveScrollPosition = true
        
        let textChangedExternally = text != coordinator.lastTextFromView
        let selectionChangedExternally = clampedInsertionPoint != coordinator.lastSelectionFromView
        let canApplyExternalUpdates = !hasMarkedText
        
        if canApplyExternalUpdates && textChangedExternally && textView.string != text {
            coordinator.suppressTextDidChange = true
            textView.string = text
            coordinator.lastTextFromView = text
        }
        
        // Keep cursor in sync for external updates and when focus is restored.
        if canApplyExternalUpdates &&
            (selectionChangedExternally || !isFirstResponder) &&
            textView.selectedRange.location != clampedInsertionPoint {
            coordinator.suppressSelectionDidChange = true
            textView.setSelectedRange(NSRange(location: clampedInsertionPoint, length: 0))
            coordinator.lastSelectionFromView = clampedInsertionPoint
        }
        if shouldFocus &&
            textView.window?.firstResponder !== textView &&
            textView.acceptsFirstResponder {
            textView.window?.makeFirstResponder(textView)
        }
        textView.setPrompt(prompt)
        textView.invalidateIntrinsicContentSize()
        nsView.invalidateIntrinsicContentSize()
        
        // Restore scroll position after layout update
        Task { @MainActor in
            nsView.contentView.scroll(to: currentScrollPosition)
            textView.shouldPreserveScrollPosition = false
        }
    }
    
    @MainActor
    class Coordinator: NSObject, NSTextViewDelegate {
        
        var parent: MultilineTextField
        var suppressTextDidChange: Bool = false
        var suppressSelectionDidChange: Bool = false
        var lastTextFromView: String
        var lastSelectionFromView: Int
        
        init(_ parent: MultilineTextField) {
            self.parent = parent
            self.lastTextFromView = parent.text
            self.lastSelectionFromView = parent.insertionPoint
        }
        
        var onImageDrop: ((URL) -> Void)? {
            return parent.onImageDrop
        }
        
        func textDidChange(
            _ notification: Notification
        ) {
            guard let textView = notification.object as? NSTextView else { return }
            // Don't update during IME composition.
            if textView.hasMarkedText() { return }
            // Ignore only matching synthetic notifications from programmatic updates.
            if suppressTextDidChange {
                suppressTextDidChange = false
                if textView.string == lastTextFromView {
                    return
                }
            }
            let newString = textView.string
            let cursor = parent.clampedCursor(textView.selectedRange.location, in: newString)
            lastTextFromView = newString
            lastSelectionFromView = cursor
            parent.text = newString
            parent.insertionPoint = cursor
            textView.invalidateIntrinsicContentSize()
            textView.enclosingScrollView?.invalidateIntrinsicContentSize()
        }
        
        func textViewDidChangeSelection(
            _ notification: Notification
        ) {
            guard let textView = notification.object as? NSTextView else { return }
            // Ignore only matching synthetic notifications from programmatic selection updates.
            if suppressSelectionDidChange {
                suppressSelectionDidChange = false
                if textView.selectedRange.location == lastSelectionFromView {
                    return
                }
            }
            let cursor = parent.clampedCursor(textView.selectedRange.location, in: textView.string)
            lastSelectionFromView = cursor
            if parent.insertionPoint != cursor {
                parent.insertionPoint = cursor
            }
        }
    }
}

class PromptingScrollView: NSScrollView {
    
    // Maximum height before scrolling kicks in (approximately 10 lines of text)
    private let maxHeightBeforeScrolling: CGFloat = 200
    
    override var intrinsicContentSize: NSSize {
        if let docView = self.documentView {
            var size = docView.intrinsicContentSize
            size.width = NSView.noIntrinsicMetric
            // Cap the height to enable scrolling for long text
            size.height = min(size.height, maxHeightBeforeScrolling)
            return size
        }
        return super.intrinsicContentSize
    }
    
}

class PromptingTextView: NSTextView {
    
    private var prompt: String = ""
    var onImageDrop: ((URL) -> Void)?
    var shouldPreserveScrollPosition: Bool = false
    
    private static let logger: Logger = .init(
        subsystem: Bundle.main.logSubsystem,
        category: String(describing: PromptingTextView.self)
    )
    
    override var intrinsicContentSize: NSSize {
        // Get font info
        guard let layoutManager = self.layoutManager, let textContainer = self.textContainer else {
            return super.intrinsicContentSize
        }
        layoutManager.ensureLayout(for: textContainer)
        let usedRect = layoutManager.usedRect(for: textContainer)
        let font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        let lineHeight = font.ascender - font.descender + font.leading
        // Calculate dimensions
        let minHeight = lineHeight + self.textContainerInset.height * 2
        let neededHeight = max(minHeight, usedRect.height + self.textContainerInset.height * 2)
        let width = self.enclosingScrollView?.frame.width ?? usedRect.width
        return NSSize(width: width, height: neededHeight)
    }
    
    override func scrollRangeToVisible(_ range: NSRange) {
        // Only allow automatic scrolling if we're not preserving scroll position
        if !shouldPreserveScrollPosition {
            super.scrollRangeToVisible(range)
        }
    }
    
    override func draw(
        _ dirtyRect: NSRect
    ) {
        super.draw(dirtyRect)
        if string.isEmpty, !prompt.isEmpty {
            let attrs: [NSAttributedString.Key: Any] = [
                .foregroundColor: NSColor.secondaryLabelColor,
                .font: NSFont.systemFont(ofSize: NSFont.systemFontSize)
            ]
            let rect = bounds.insetBy(dx: 5, dy: 4)
            (prompt as NSString).draw(in: rect, withAttributes: attrs)
        }
    }
    
    func setPrompt(
        _ prompt: String
    ) {
        if self.prompt != prompt {
            self.prompt = prompt
            needsDisplay = true
        }
    }
    
    /// Function to force pasting as plain text
    override func paste(
        _ sender: Any?
    ) {
        let pasteboard = NSPasteboard.general
        
        let fileURLClasses: [AnyClass] = [NSURL.self]
        let options: [NSPasteboard.ReadingOptionKey: Any] = [
            .urlReadingFileURLsOnly: true
        ]
        if let urls = pasteboard.readObjects(forClasses: fileURLClasses, options: options) as? [URL],
           !urls.isEmpty {
            Self.logger.info("Handling pasted file URLs")
            if handleFileURLs(urls) {
                return
            }
        }
        
        if let imageData = pasteboard.data(forType: .png) ?? pasteboard.data(forType: .tiff) {
            Self.logger.info("Handling pasted image data")
            if handleImageData(imageData, pasteboard: pasteboard) {
                return
            }
        }
        
        if let plainText = pasteboard.string(forType: .string) {
            self.insertText(plainText, replacementRange: self.selectedRange())
        } else {
            super.paste(sender)
        }
    }
    
    // MARK: - Drag and Drop Support
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if canHandleDrag(sender) {
            return .copy
        }
        return []
    }
    
    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        if canHandleDrag(sender) {
            return .copy
        }
        return []
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        Self.logger.info("performDragOperation called")
        let pasteboard = sender.draggingPasteboard
        
        Self.logger.info("Pasteboard types: \(pasteboard.types?.map { $0.rawValue } ?? [], privacy: .public)")
        
        // Try to handle image data first (for screenshots)
        if let imageData = pasteboard.data(forType: .png) ?? pasteboard.data(forType: .tiff) {
            Self.logger.info("Found image data, handling...")
            return handleImageData(imageData, pasteboard: pasteboard)
        }
        
        // Try to handle file URLs
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
           !urls.isEmpty {
            return handleFileURLs(urls)
        }
        
        Self.logger.warning("No valid data found in drop")
        return false
    }
    
    private func canHandleDrag(_ sender: NSDraggingInfo) -> Bool {
        let pasteboard = sender.draggingPasteboard
        
        // Check for image data (screenshots)
        if pasteboard.data(forType: .png) != nil ||
            pasteboard.data(forType: .tiff) != nil {
            return true
        }
        
        // Check for file URLs
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], !urls.isEmpty {
            return true
        }
        
        return false
    }
    
    private func handleImageData(_ imageData: Data, pasteboard: NSPasteboard) -> Bool {
        Self.logger.info("handleImageData called with data size: \(imageData.count, privacy: .public)")
        
        guard let image = NSImage(data: imageData) else {
            Self.logger.error("Failed to create NSImage from dropped data")
            return false
        }
        
        Self.logger.info("Created NSImage with size: \(image.size.width, privacy: .public)x\(image.size.height, privacy: .public)")
        
        // Determine the file extension based on the data type
        let fileExtension: String
        if pasteboard.data(forType: .png) != nil {
            fileExtension = "png"
        } else {
            fileExtension = "png" // Default to PNG for TIFF
        }
        
        // Create a temporary file to save the image
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileName = "Screenshot-\(UUID().uuidString).\(fileExtension)"
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        Self.logger.info("Will save to: \(fileURL.path, privacy: .public)")
        
        // Convert image to appropriate format and save
        guard let tiffData = image.tiffRepresentation else {
            Self.logger.error("Failed to get TIFF representation of image")
            return false
        }
        
        let bitmapImageRep = NSBitmapImageRep(data: tiffData)
        let imageDataToSave: Data?
        
        if fileExtension == "png" {
            imageDataToSave = bitmapImageRep?.representation(using: .png, properties: [:])
        } else {
            imageDataToSave = bitmapImageRep?.representation(using: .jpeg, properties: [:])
        }
        
        guard let finalImageData = imageDataToSave else {
            Self.logger.error("Failed to convert image to \(fileExtension, privacy: .public)")
            return false
        }
        
        do {
            try finalImageData.write(to: fileURL)
            Self.logger.info("Successfully saved dropped image to: \(fileURL.path, privacy: .public)")
            
            Task { @MainActor [weak self] in
                Self.logger.info("Calling onImageDrop callback")
                self?.onImageDrop?(fileURL)
            }
            return true
        } catch {
            Self.logger.error("Failed to save image: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }
    
    private func handleFileURLs(_ urls: [URL]) -> Bool {
        guard !urls.isEmpty else {
            Self.logger.warning("No file URLs provided to handleFileURLs")
            return false
        }
        
        Self.logger.info("Handling \(urls.count, privacy: .public) file URLs")
        
        for url in urls {
            Self.logger.info("Processing file URL: \(url.path, privacy: .public)")
            Task { @MainActor [weak self] in
                self?.onImageDrop?(url)
            }
        }
        
        return true
    }
}

extension MultilineTextField {
    
    func isProgrammaticTextChange(
        old: String,
        new: String
    ) -> Bool {
        abs(old.count - new.count) > 1 || (old.count > 1 && new.count > 1 && old != new)
    }
    
}

struct ChatPromptEditor: View {

    @EnvironmentObject private var promptController: PromptController

    @AppStorage("useCommandReturn") private var useCommandReturn: Bool = Settings.useCommandReturn
    var sendDescription: String {
        return String(localized: "Enter a message. Press ") + Settings.SendShortcut(self.useCommandReturn).rawValue + String(localized: " to send.")
    }

    var isFocused: FocusState<Bool>.Binding
    @Binding var isRecording: Bool

    var useAttachments: Bool = true
    var useDictation: Bool = true

    /// A `Bool` controlling whether space is reserved for options below the text field
    var bottomOptions: Bool = false

    var cornerRadius = 16.0
    var rect: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    var outlineColor: Color {
        if isRecording {
            return .red
        } else if isFocused.wrappedValue {
            return .accentColor
        }
        return .primary
    }

    var body: some View {
        MultilineTextField(
            text: self.$promptController.prompt,
            insertionPoint: self.$promptController.insertionPoint,
            shouldFocus: self.isFocused.wrappedValue,
            prompt: sendDescription,
            onImageDrop: { url in
                Task {
                    await self.promptController.addFile(url)
                }
            }
        )
        .textFieldStyle(.plain)
        .frame(maxWidth: .infinity)
        .if(self.useAttachments) { view in
            view
                .padding(.leading, 24)
        }
        .if(self.useDictation) { view in
            view
                .padding(.trailing, 21)
        }
        .if(!self.useAttachments) { view in
            view
                .padding(.leading, 4)
        }
        .if(!self.useDictation) { view in
            view
                .padding(.trailing, 4)
        }
        .if(self.bottomOptions) { view in
            view
                .padding(.bottom, 30)
        }
        .padding(.vertical, 5)
        .cornerRadius(cornerRadius)
        .background(
            LinearGradient(
                colors: [
                    Color.textBackground,
                    Color.textBackground.opacity(0.9),
                    Color.textBackground.opacity(0.75),
                    Color.textBackground.opacity(0.5)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .mask(rect)
        .overlay(
            rect
                .stroke(style: StrokeStyle(lineWidth: 1))
                .foregroundStyle(outlineColor)
        )
        .animation(
            isFocused.wrappedValue ? .easeIn(duration: 0.2) : .easeOut(duration: 0.0),
            value: isFocused.wrappedValue
        )
    }

}
