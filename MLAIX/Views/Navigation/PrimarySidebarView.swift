//
//  PrimarySidebarView.swift
//  MLAIX
//
//  Primary (first) column of the 3-column navigation split view.
//

import SwiftUI

/// Top-level section in the main window navigation.
enum PrimarySection: String, CaseIterable, Identifiable {
    case conversations
    case tools
    case models
    case memory
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .conversations: return String(localized: "Conversations")
        case .tools: return String(localized: "Tools")
        case .models: return String(localized: "Models")
        case .memory: return String(localized: "Memory")
        case .settings: return String(localized: "Settings")
        }
    }

    var subtitle: String {
        switch self {
        case .conversations: return String(localized: "Chats and threads")
        case .tools: return String(localized: "Dashboard, Diagrammer, more")
        case .models: return String(localized: "Browse and manage models")
        case .memory: return String(localized: "Saved memories")
        case .settings: return String(localized: "Preferences")
        }
    }

    var systemImage: String {
        switch self {
        case .conversations: return "bubble.left.and.text.bubble.right"
        case .tools: return "wrench.and.screwdriver"
        case .models: return "cpu"
        case .memory: return "brain"
        case .settings: return "gearshape"
        }
    }
}

struct PrimarySidebarView: View {
    @Binding var selection: PrimarySection?

    var body: some View {
        VStack(spacing: 0) {
            sidebarHeader
            Divider()
            List(PrimarySection.allCases, selection: $selection) { section in
                sidebarRow(section: section)
                    .tag(section)
                    .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                    .listRowBackground(selection == section ? Color.accentColor.opacity(0.08) : Color.clear)
                    .accessibilityIdentifier("sidebar.\(section.rawValue)")
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .accessibilityIdentifier("primarySidebar")
        }
        .background(.regularMaterial.opacity(0.5))
        .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 280)
    }

    private var sidebarHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "bubble.left.and.text.bubble.right.fill")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("MLAIX")
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
    }

    private func sidebarRow(section: PrimarySection) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Label(section.title, systemImage: section.systemImage)
                .font(.system(.body, weight: .medium))
            Text(section.subtitle)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    PrimarySidebarView(selection: .constant(.conversations))
        .frame(width: 200)
}
