//
//  MLAIXAppIntents.swift
//  MLAIXShared – Siri Shortcuts & App Intents (iOS, macOS)
//

import AppIntents
import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Open MLAIX

struct OpenMLAIXIntent: AppIntent {
    static let title: LocalizedStringResource = "Open MLAIX"
    static let description = IntentDescription("Opens the MLAIX app.")

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            openURL(MLAIXURLScheme.base)
        }
        return .result()
    }
}

// MARK: - New Chat

struct NewChatIntent: AppIntent {
    static let title: LocalizedStringResource = "New Chat"
    static let description = IntentDescription("Opens MLAIX and starts a new conversation.")

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            openURL(MLAIXURLScheme.newChat)
        }
        return .result()
    }
}

// MARK: - Ask MLAIX

struct AskMLAIXIntent: AppIntent {
    static let title: LocalizedStringResource = "Ask MLAIX"
    static let description = IntentDescription("Opens MLAIX with a prompt ready to send.")

    @Parameter(title: "Prompt")
    var prompt: String

    static var parameterSummary: some ParameterSummary {
        Summary("Ask MLAIX \(\.$prompt)")
    }

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            openURL(MLAIXURLScheme.ask(prompt: prompt))
        }
        return .result()
    }
}

// MARK: - URL Scheme

private enum MLAIXURLScheme {
    static let base = "mlaix://"
    static let newChat = "mlaix://new-chat"
    static func ask(prompt: String) -> String {
        let encoded = prompt.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? prompt
        return "mlaix://ask?prompt=\(encoded)"
    }
}

// MARK: - URL Opener (cross-platform)

private func openURL(_ string: String) {
    guard let url = URL(string: string) else { return }
    #if canImport(UIKit)
    UIApplication.shared.open(url)
    #elseif canImport(AppKit)
    NSWorkspace.shared.open(url)
    #endif
}

// MARK: - Shortcuts Provider

struct MLAIXShortcutsProvider: AppShortcutsProvider {
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenMLAIXIntent(),
            phrases: ["Open \(.applicationName)"],
            shortTitle: "Open MLAIX",
            systemImageName: "brain.head.profile"
        )
        AppShortcut(
            intent: NewChatIntent(),
            phrases: ["New chat in \(.applicationName)"],
            shortTitle: "New Chat",
            systemImageName: "plus.bubble"
        )
        AppShortcut(
            intent: AskMLAIXIntent(),
            phrases: ["Ask \(.applicationName) a question"],
            shortTitle: "Ask MLAIX",
            systemImageName: "bubble.left.and.bubble.right"
        )
    }
}
