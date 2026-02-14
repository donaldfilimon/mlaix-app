//
//  SettingsView.swift
//  MLAIX
//
//  macOS Settings: sidebar navigation + detail pane (native style).
//

import SwiftUI

private enum SettingsSection: String, CaseIterable, Identifiable {
    case general
    case appleIntelligence
    case retrieval
    case inference
    case appearance
    case deepResearch

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: return String(localized: "General")
        case .appleIntelligence: return String(localized: "Apple Intelligence")
        case .retrieval: return String(localized: "Retrieval")
        case .inference: return String(localized: "Inference")
        case .appearance: return String(localized: "Appearance")
        case .deepResearch: return String(localized: "Deep Research")
        }
    }

    var systemImage: String {
        switch self {
        case .general: return "gear"
        case .appleIntelligence: return "sparkles"
        case .retrieval: return "magnifyingglass"
        case .inference: return "brain.fill"
        case .appearance: return "paintbrush.fill"
        case .deepResearch: return "binoculars"
        }
    }
}

struct SettingsView: View {
    @State private var selection: SettingsSection? = .general

    var body: some View {
        NavigationSplitView {
            List(SettingsSection.allCases, selection: $selection) { section in
                Label(section.title, systemImage: section.systemImage)
                    .tag(section)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 260)
        } detail: {
            detailContent(for: selection ?? .general)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(20)
        }
        .frame(minWidth: 560, minHeight: 420)
    }

    @ViewBuilder
    private func detailContent(for section: SettingsSection) -> some View {
        switch section {
        case .general:
            GeneralSettingsView()
        case .appleIntelligence:
            AppleIntelligenceSettingsView()
        case .retrieval:
            RetrievalSettingsView()
        case .inference:
            InferenceSettingsView()
        case .appearance:
            AppearanceSettingsView()
        case .deepResearch:
            DeepResearchSettingsView()
        }
    }
}
