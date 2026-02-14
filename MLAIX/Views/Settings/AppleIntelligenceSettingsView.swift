//
//  AppleIntelligenceSettingsView.swift
//  MLAI
//
//  macOS 26 Apple Intelligence (Foundation Models) settings.
//

import SwiftUI

struct AppleIntelligenceSettingsView: View {

    @AppStorage("useFoundationModels") private var useFoundationModels: Bool = InferenceSettings.useFoundationModels

    var body: some View {
        Form {
            Section {
                foundationModelsToggle
            } header: {
                Text("Apple Intelligence")
            } footer: {
                Text("Apple Foundation Models provide on-device chat when Apple Intelligence is enabled in System Settings. MLAIX falls back to local or remote models for tools, web search, and deep research.")
            }
        }
        .formStyle(.grouped)
        .onChange(of: useFoundationModels, initial: false) { _, _ in
            NavigationState.shared.inferenceConfigChanged = true
        }
    }

    private var foundationModelsToggle: some View {
        let statusText = FoundationModelsSupport.availabilityDescription
        let isAvailable = FoundationModelsSupport.isAvailable
        return HStack(alignment: .top) {
            VStack(alignment: .leading) {
                Text("Use Apple Foundation Models")
                    .font(.title3)
                    .bold()
                Text("Use Apple Intelligence for chat when available.")
                    .font(.caption)
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(isAvailable ? .green : .secondary)
            }
            Spacer()
            Toggle("", isOn: $useFoundationModels.animation(.linear))
                .labelsHidden()
                .disabled(!isAvailable)
        }
    }
}

#Preview {
    AppleIntelligenceSettingsView()
}
