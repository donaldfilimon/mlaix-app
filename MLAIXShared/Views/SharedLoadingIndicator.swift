//
//  SharedLoadingIndicator.swift
//  MLAIXShared
//

import SwiftUI

/// Unified loading indicator for chat generation.
public struct SharedLoadingIndicator: View {
    public init() {}

    public var body: some View {
        HStack(spacing: 8) {
            ProgressView()
            Text("Generating…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
