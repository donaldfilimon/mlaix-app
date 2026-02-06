//
//  MLAIXWatchApp.swift
//  MLAIX Apple Watch companion
//

import SwiftUI

@main
struct MLAIXWatchApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    private let openURL = URL(string: "mlaix://new-chat")

    var body: some View {
        Group {
            if let url = openURL {
                Link(destination: url) {
                    watchContent
                }
                .buttonStyle(.plain)
            } else {
                watchContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var watchContent: some View {
        VStack(spacing: 10) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 36))
                .foregroundStyle(.tint)
            Text("MLAIX")
                .font(.headline)
            Text("Open on iPhone")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("MLAIX. Tap to open on iPhone.")
    }
}
