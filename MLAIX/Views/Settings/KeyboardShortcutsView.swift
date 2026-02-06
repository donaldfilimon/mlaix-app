//
//  KeyboardShortcutsView.swift
//  MLAI
//
//  Reference for keyboard shortcuts and commands.
//

import SwiftUI

struct KeyboardShortcutsView: View {

    var body: some View {
        List {
            Section("Conversation") {
                shortcutRow("New Conversation", "⌘N")
                shortcutRow("Send Message", "⌘↵")
                shortcutRow("Toggle Canvas", "⌘⌥↵")
                shortcutRow("Toggle Functions", "⌘⇧F")
                if RetrievalSettings.canUseWebSearch {
                    shortcutRow("Toggle Web Search", "⌘⇧R")
                }
            }
            Section("Experts") {
                shortcutRow("Expert 1–9", "⌘1" + "–" + "⌘9")
                shortcutRow("Previous Expert", "⌘[")
                shortcutRow("Next Expert", "⌘]")
            }
            Section("Input") {
                shortcutRow("Model Selector", "⌘K")
                shortcutRow("Attachments", "⌘⇧A")
                shortcutRow("Dictation", "⌘D")
            }
            Section("Inline Writing Assistant") {
                shortcutRow("Toggle Assistant", "⌘⌃I")
                shortcutRow("Accept Next Token", "Tab")
                shortcutRow("Accept All", "⇧Tab")
            }
            Section("Window") {
                shortcutRow("Full Screen", "⌃⌘F")
                shortcutRow("Help", "⌘⇧/")
                shortcutRow("Keyboard Shortcuts", "⌘⇧K")
            }
        }
        .navigationTitle("Keyboard Shortcuts")
        .frame(minWidth: 320, minHeight: 400)
    }

    private func shortcutRow(_ action: String, _ keys: String) -> some View {
        HStack {
            Text(action)
            Spacer()
            Text(keys)
                .foregroundStyle(.secondary)
                .font(.system(.body, design: .monospaced))
        }
    }
}
