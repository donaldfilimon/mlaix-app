//
//  MessageTextContentView.swift
//  MLAI
//
//  Created by Bean John on 11/12/24.
//

import LaTeXSwiftUI
import MarkdownUI
import Splash
import SwiftUI

struct MessageTextContentView: View {
    
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var cachedMarkdown: AnyView? = nil
    @State private var processedText: String = ""
    @State private var lastUpdate: Date = Date()
    @State private var throttleTimer: Timer?
    
    var text: String
    private let imageScaleFactor: CGFloat = 1.0
    private let throttleInterval: TimeInterval = 0.4
    
    private var theme: Splash.Theme {
        switch colorScheme {
            case .dark:
                return .wwdc17(withFont: .init(size: 16))
            default:
                return .sunset(withFont: .init(size: 16))
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            if let cached = cachedMarkdown {
                cached
            } else {
                markdownView(processedText.isEmpty ? text.convertLaTeX() : processedText)
            }
        }
        .onAppear {
            updateProcessedTextAndMarkdown(text)
        }
        .onChange(of: self.text) { _, newText in
            updateProcessedTextAndMarkdown(newText)
        }
        .onDisappear {
            throttleTimer?.invalidate()
        }
    }
    
    @ViewBuilder
    private func markdownView(
        _ text: String
    ) -> some View {
        Markdown(MarkdownContent(text))
            .markdownTheme(.gitHub)
            .markdownCodeSyntaxHighlighter(.splash(theme: theme))
            .markdownImageProvider(MarkdownImageProvider(scaleFactor: imageScaleFactor))
            .markdownInlineImageProvider(MarkdownInlineImageProvider(scaleFactor: imageScaleFactor))
            .textSelection(.enabled)
    }
    
    private func updateProcessedTextAndMarkdown(
        _ newText: String
    ) {
        let converted = newText.convertLaTeX()
        processedText = converted
        
        let now = Date()
        let timeSinceLast = now.timeIntervalSince(lastUpdate)
        if timeSinceLast >= throttleInterval {
            lastUpdate = now
            updateCachedMarkdown(with: converted)
        } else {
            throttleTimer?.invalidate()
            let interval = throttleInterval - timeSinceLast
            throttleTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [self] _ in
                MainActor.assumeIsolated {
                    self.lastUpdate = Date()
                    self.updateCachedMarkdown(with: converted)
                }
            }
        }
    }
    
    private func updateCachedMarkdown(
        with text: String
    ) {
        // Keep markdown rendering on MainActor since it's a UI operation
        // and avoids Sendable issues with AnyView and theme
        let currentTheme = self.theme
        let scaleFactor = self.imageScaleFactor

        self.cachedMarkdown = AnyView(
            Markdown(MarkdownContent(text))
                .markdownTheme(.gitHub)
                .markdownCodeSyntaxHighlighter(.splash(theme: currentTheme))
                .markdownImageProvider(MarkdownImageProvider(scaleFactor: scaleFactor))
                .markdownInlineImageProvider(MarkdownInlineImageProvider(scaleFactor: scaleFactor))
                .textSelection(.enabled)
        )
    }
    
}
