//
//  SharedEmptyChatView.swift
//  MLAIXShared
//

import SwiftUI

/// Unified empty chat state view across platforms.
public struct SharedEmptyChatView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Start a conversation")
                .font(.title3)
            Text("Send a message to get a response from the model.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}
