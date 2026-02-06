//
//  SettingsView.swift
//  MLAI
//
//  Created by Bean John on 10/14/24.
//

import SwiftUI

struct SettingsView: View {

    var body: some View {
        TabView {
            Tab("General", systemImage: "gear") { GeneralSettingsView() }
            Tab("Apple Intelligence", systemImage: "sparkles") { AppleIntelligenceSettingsView() }
            Tab("Retrieval", systemImage: "magnifyingglass") { RetrievalSettingsView() }
            Tab("Inference", systemImage: "brain.fill") { InferenceSettingsView() }
            Tab("Appearance", systemImage: "paintbrush.fill") { AppearanceSettingsView() }
            Tab("Deep Research", systemImage: "binoculars") { DeepResearchSettingsView() }
        }
		.frame(maxWidth: 600)
		.liquidGlassPanel(cornerRadius: 18)
		.padding()
    }
	
}
