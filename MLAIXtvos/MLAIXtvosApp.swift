//
//  MLAIXtvosApp.swift
//  MLAIX tvOS (placeholder)
//

import SwiftUI
import MLAIXShared

@main
struct MLAIXtvosApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 80))
                .foregroundStyle(.secondary)
            Text("MLAIX")
                .font(.largeTitle)
            Text("Coming soon on tvOS")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("Use MLAIX on macOS or iOS for the full experience.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .focusable()
    }
}
