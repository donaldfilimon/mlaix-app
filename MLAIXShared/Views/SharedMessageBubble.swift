//
//  SharedMessageBubble.swift
//  MLAIXShared
//

import SwiftUI
import MarkdownUI

/// Unified message bubble view for chat (macOS, iOS, iPadOS, tvOS).
public struct SharedMessageBubble: View {
    public let text: String
    public let isUser: Bool

    public init(text: String, isUser: Bool) {
        self.text = text
        self.isUser = isUser
    }

    public var body: some View {
        HStack {
            if isUser { Spacer(minLength: 48) }
            if isUser {
                Text(text)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.accentColor.opacity(0.2))
                    .foregroundStyle(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .accessibilityLabel("You said: \(text)")
            } else {
                Markdown(text)
                    .markdownTheme(.gitHub)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .accessibilityLabel("Assistant: \(text)")
            }
            if !isUser { Spacer(minLength: 48) }
        }
    }
}
