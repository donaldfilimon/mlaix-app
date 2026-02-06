//
//  DeepResearchSettingsView.swift
//  MLAI
//
//  Created by Codex on 2/5/26.
//

import SwiftUI

struct DeepResearchSettingsView: View {
    
    @AppStorage("deepResearchDepth") private var depthRaw: String = DeepResearchSettings.depth.rawValue
    @AppStorage("deepResearchMinSources") private var minSources: Int = DeepResearchSettings.minSources
    @AppStorage("deepResearchMaxSources") private var maxSources: Int = DeepResearchSettings.maxSources
    @AppStorage("deepResearchMinToolCalls") private var minToolCalls: Int = DeepResearchSettings.minToolCalls
    @AppStorage("deepResearchMaxSections") private var maxSections: Int = DeepResearchSettings.maxSections
    
    private var depth: DeepResearchDepth {
        DeepResearchDepth(rawValue: depthRaw) ?? .balanced
    }
    
    var body: some View {
        Form {
            Section {
                depthPicker
                sourcesRange
                toolCallsStepper
                sectionsStepper
            } header: {
                Text("Deep Research")
            }
        }
        .formStyle(.grouped)
    }
    
    private var depthPicker: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                Text("Research Depth")
                    .font(.title3)
                    .bold()
                Text("Controls how many sources and tool calls Deep Research targets by default.")
                    .font(.caption)
            }
            Spacer()
            Picker("", selection: $depthRaw) {
                ForEach(DeepResearchDepth.allCases) { option in
                    Text(option.rawValue.capitalized).tag(option.rawValue)
                }
            }
            .onChange(of: depthRaw) {
                if let next = DeepResearchDepth(rawValue: depthRaw) {
                    DeepResearchSettings.depth = next
                    minSources = DeepResearchSettings.minSources
                    maxSources = DeepResearchSettings.maxSources
                    minToolCalls = DeepResearchSettings.minToolCalls
                    maxSections = DeepResearchSettings.maxSections
                }
            }
        }
    }
    
    private var sourcesRange: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                Text("Sources Range")
                    .font(.title3)
                    .bold()
                Text("Target range of sources per section.")
                    .font(.caption)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 8) {
                Stepper("Min \(minSources)", value: $minSources, in: 1...50)
                    .onChange(of: minSources) { _, newValue in
                        if newValue > maxSources {
                            maxSources = newValue
                        }
                        DeepResearchSettings.minSources = minSources
                        DeepResearchSettings.maxSources = maxSources
                    }
                Stepper("Max \(maxSources)", value: $maxSources, in: 1...75)
                    .onChange(of: maxSources) { _, newValue in
                        if newValue < minSources {
                            minSources = newValue
                        }
                        DeepResearchSettings.maxSources = maxSources
                        DeepResearchSettings.minSources = minSources
                    }
            }
        }
    }
    
    private var toolCallsStepper: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                Text("Minimum Tool Calls")
                    .font(.title3)
                    .bold()
                Text("Ensures the agent keeps searching before concluding.")
                    .font(.caption)
            }
            Spacer()
            Stepper("Min \(minToolCalls)", value: $minToolCalls, in: 1...40)
                .onChange(of: minToolCalls) { _, newValue in
                    DeepResearchSettings.minToolCalls = newValue
                }
        }
    }
    
    private var sectionsStepper: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                Text("Maximum Sections")
                    .font(.title3)
                    .bold()
                Text("Limits the number of report sections to keep output focused.")
                    .font(.caption)
            }
            Spacer()
            Stepper("Max \(maxSections)", value: $maxSections, in: 1...12)
                .onChange(of: maxSections) { _, newValue in
                    DeepResearchSettings.maxSections = newValue
                }
        }
    }
}

#Preview {
    DeepResearchSettingsView()
}
