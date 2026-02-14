//
//  ModelSelectorDropdown.swift
//  MLAI
//
//  Created by John Bean on 11/5/25.
//

import SwiftUI

struct ModelSelectorDropdown: View {
    
    @Environment(\.colorScheme) private var colorScheme
    
    @Environment(ExpertManager.self) private var expertManager
    @Environment(ConversationState.self) private var conversationState
    
    @AppStorage("endpoint") private var serverEndpoint: String = InferenceSettings.endpoint
    @Binding var serverModelName: String
    @AppStorage("serverModelHasVision") private var serverModelHasVision: Bool = InferenceSettings.serverModelHasVision
    
    @State private var remoteModelNames: [String] = []
    @State private var customModelNames: [String] = InferenceSettings.customModelNames
    @State private var isManagingCustomModel: Bool = false
    @State private var showingDropdown: Bool = false
    @State private var searchText: String = ""
    @State private var localModelsListId: UUID = UUID()
    @State private var remoteServerReachable: Bool = false
    
    @Environment(ModelManager.self) private var modelManager
    @Environment(Model.self) private var model
    
    // Scroll to active model
    @State private var scrollToLocal: Bool = false
    @State private var scrollToRemote: Bool = false
    
    var selectedExpert: Expert? {
        guard let selectedExpertId = conversationState.selectedExpertId else {
            return nil
        }
        return expertManager.getExpert(id: selectedExpertId)
    }
    
    var toolbarTextColor: Color {
        guard let selectedExpert = selectedExpert else {
            return .primary
        }
        // Use the same logic as expert label/icon for consistency
        return selectedExpert.color.adaptedTextColor
    }
    
    // Get the current model name for display
    var currentModelName: String {
        if let selectedModelName = model.selectedModelName {
            return ModelNameFormatter.formatModelName(selectedModelName)
        } else if InferenceSettings.useServer {
            return serverModelName.isEmpty ? "No Model Selected" : ModelNameFormatter.formatModelName(serverModelName)
        } else {
            return "No Model Selected"
        }
    }
    
    // Filter models based on fuzzy search
    var filteredLocalModels: [ModelManager.ModelFile] {
        let filtered = searchText.isEmpty
        ? modelManager.models
        : modelManager.models.filter { model in
            ModelSearchMatcher.fuzzyMatch(model.name, query: searchText)
        }
        
        // Sort by parameter count (largest first)
        return filtered.sorted { model1, model2 in
            let params1 = model1.name.modelParameterCount
            let params2 = model2.name.modelParameterCount
            
            if params1 > 0 && params2 > 0 {
                return params1 > params2
            }
            if params1 > 0 { return true }
            if params2 > 0 { return false }
            
            return model1.name.localizedStandardCompare(model2.name) == .orderedAscending
        }
    }
    
    var filteredRemoteModels: [String] {
        let allRemoteModels = remoteModelNames + customModelNames
        let filtered = searchText.isEmpty
        ? allRemoteModels
        : allRemoteModels.filter { modelName in
            ModelSearchMatcher.fuzzyMatch(modelName, query: searchText)
        }
        
        // Sort by parameter count (largest first)
        return filtered.sortedByModelSize()
    }
    
    var body: some View {
        Button {
            showingDropdown.toggle()
        } label: {
            HStack(spacing: 4) {
                Text(currentModelName)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundStyle(toolbarTextColor)
            .symbolRenderingMode(.monochrome)
            .padding(.horizontal, 12)
        }
        .keyboardShortcut("k", modifiers: [.command])
        .buttonStyle(.plain)
        .popover(isPresented: $showingDropdown) {
            dropdownContent
                .frame(width: 360, height: 480)
        }
        .sheet(isPresented: self.$isManagingCustomModel) {
            ModelNameMenu.CustomModelsEditor(
                customModelNames: self.$customModelNames,
                isPresented: self.$isManagingCustomModel
            )
            .frame(minWidth: 400)
        }
        .task {
            // Get available models
            await self.refreshModelNames()
            // Check remote server reachability to update the display
            if InferenceSettings.useServer {
                self.remoteServerReachable = await model.remoteServerIsReachable()
            } else {
                self.remoteServerReachable = false
            }
        }
.onChange(of: serverEndpoint) { _, _ in
        Task { @MainActor in
                await self.refreshModelNames()
                if InferenceSettings.useServer {
                    self.remoteServerReachable = await model.remoteServerIsReachable()
                } else {
                    self.remoteServerReachable = false
                }
            }
        }
        .onChange(of: NavigationState.shared.inferenceConfigChanged) { _, _ in
            self.localModelsListId = UUID()
            Task { @MainActor in
                if InferenceSettings.useServer {
                    self.remoteServerReachable = await model.remoteServerIsReachable()
                } else {
                    self.remoteServerReachable = false
                }
            }
        }
        .onChange(of: self.serverModelName) { _, _ in
            let serverModelHasVision: Bool = KnownModel.availableModels.contains { model in
                let nameMatches: Bool = self.serverModelName.contains(model.primaryName)
                return nameMatches && model.isVision
            }
            self.serverModelHasVision = serverModelHasVision
        }
    }
    
    var dropdownContent: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.body)
                TextField("Search", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(10)
            .background(Color(.controlBackgroundColor))
            .cornerRadius(10)
            .padding([.horizontal, .top], 12)
            .padding(.bottom, 8)
            
            Divider()
            
            // Models list - Use LazyVStack for better performance
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0, pinnedViews: []) {
                        // Local Models Section
                        if !filteredLocalModels.isEmpty {
                            self.sectionHeader(
                                title: String(localized: "Local Models"),
                                id: "LocalHeader",
                                count: self.filteredLocalModels.count
                            )
                            ForEach(filteredLocalModels, id: \.name) { modelFile in
                                let capabilities = getModelCapabilities(modelFile.name)
                                LocalModelRow(
                                    modelFile: modelFile,
                                    isSelected: Settings.modelUrl == modelFile.url,
                                    isRemoteServerReachable: remoteServerReachable,
                                    isReasoning: capabilities.isReasoning,
                                    isVision: capabilities.isVision,
                                    onSelect: {
                                        selectLocalModel(modelFile)
                                    }
                                )
                                .id("Local:\(modelFile.name)")
                            }
                            .id(localModelsListId)
                        }
                        
                        // Remote Models Section
                        if !filteredRemoteModels.isEmpty {
                            if !filteredLocalModels.isEmpty {
                                Divider()
                                    .padding(.vertical, 8)
                            }
                            self.sectionHeader(
                                title: String(localized: "Remote Models"),
                                id: "RemoteHeader",
                                count: self.filteredRemoteModels.count
                            )
                            ForEach(filteredRemoteModels, id: \.self) { modelName in
                                let capabilities = getModelCapabilities(modelName)
                                RemoteModelRow(
                                    modelName: ModelNameFormatter.formatModelName(modelName),
                                    isSelected: modelName == serverModelName && InferenceSettings.useServer,
                                    isRemoteServerReachable: remoteServerReachable,
                                    isReasoning: capabilities.isReasoning,
                                    isVision: capabilities.isVision,
                                    onSelect: {
                                        selectRemoteModel(modelName)
                                    }
                                )
                                .id("Remote:\(modelName)")
                            }
                        }
                        
                        // Empty state
                        if filteredLocalModels.isEmpty && filteredRemoteModels.isEmpty {
                            VStack(spacing: 8) {
                                Text("No models found")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                if !searchText.isEmpty {
                                    Text("Try a different search term")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
                .task {
                    // Scroll to selected model after view appears
                    await Task.yield() // Let the view render first
                    
                    if !InferenceSettings.useServer {
                        // Scroll to selected local model
                        if let selectedModel = filteredLocalModels.first(where: { Settings.modelUrl == $0.url }) {
                            proxy.scrollTo("Local:\(selectedModel.name)", anchor: .center)
                        }
                    } else if InferenceSettings.useServer && !serverModelName.isEmpty {
                        // Scroll to selected remote model
                        if filteredRemoteModels.contains(serverModelName) {
                            proxy.scrollTo("Remote:\(serverModelName)", anchor: .center)
                        }
                    }
                    
                    // Reset search when opening
                    searchText = ""
                }
            }
            
            Divider()
            
            // Bottom actions
            HStack(spacing: 8) {
                Button {
                    self.isManagingCustomModel = true
                } label: {
                    Text("Manage Custom Models")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                
                Spacer()
                
                Button {
                    InferenceSettings.useServer.toggle()
                    NavigationState.shared.inferenceConfigChanged = true
                } label: {
                    Text(InferenceSettings.useServer ? "Disable Remote" : "Enable Remote")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            .padding([.horizontal, .bottom], 12)
            .padding(.top, 8)
        }
    }
    
    
    private func sectionHeader(
        title: String,
        id: String,
        count: Int
    ) -> some View {
        Text("\(title) (\(count))")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .id(id)
    }
    
    private func selectLocalModel(_ modelFile: ModelManager.ModelFile) {
        Settings.modelUrl = modelFile.url
        NavigationState.shared.inferenceConfigChanged = true
        showingDropdown = false
    }
    
    private func selectRemoteModel(_ modelName: String) {
        self.serverModelName = modelName
        // Enable remote server if not already enabled
        if !InferenceSettings.useServer {
            InferenceSettings.useServer = true
        }
        NavigationState.shared.inferenceConfigChanged = true
        showingDropdown = false
    }
    
    private func refreshModelNames() async {
        self.remoteModelNames = await LlamaServer.getAvailableModels()
    }
    
    // Get model capabilities from model name
    private func getModelCapabilities(_ modelName: String) -> (isReasoning: Bool, isVision: Bool) {
        // Clean up the model name for better matching
        var cleanedName = modelName
        
        // Remove file extensions (for local models)
        let supportedExtensions = [".gguf", ".mlx"]
        for fileExtension in supportedExtensions {
            if cleanedName.lowercased().hasSuffix(fileExtension) {
                cleanedName = String(cleanedName.dropLast(fileExtension.count))
                break
            }
        }
        
        // Remove quantization suffixes (e.g., Q4_K_M, Q8_0, etc.)
        let quantizationPatterns = [
            "-Q4_K_M", "-Q4_K_S", "-Q5_K_M", "-Q5_K_S", "-Q6_K", "-Q8_0",
            "_Q4_K_M", "_Q4_K_S", "_Q5_K_M", "_Q5_K_S", "_Q6_K", "_Q8_0",
            "-q4_k_m", "-q4_k_s", "-q5_k_m", "-q5_k_s", "-q6_k", "-q8_0",
            "_q4_k_m", "_q4_k_s", "_q5_k_m", "_q5_k_s", "_q6_k", "_q8_0"
        ]
        for pattern in quantizationPatterns {
            if cleanedName.hasSuffix(pattern) {
                cleanedName = String(cleanedName.dropLast(pattern.count))
                break
            }
        }
        
        // Try direct lookup first
        if let knownModel = KnownModel(identifier: cleanedName) {
            return (knownModel.isReasoningModel, knownModel.isVision)
        }
        
        // If direct lookup fails, try with original name
        if cleanedName != modelName, let knownModel = KnownModel(identifier: modelName) {
            return (knownModel.isReasoningModel, knownModel.isVision)
        }
        
        // If still no match, try fuzzy matching with normalized names
        let normalizedSearch = cleanedName
            .lowercased()
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: ".", with: "")
        
        for model in KnownModel.availableModels {
            let normalizedModelName = model.primaryName
                .lowercased()
                .replacingOccurrences(of: "-", with: "")
                .replacingOccurrences(of: "_", with: "")
                .replacingOccurrences(of: ".", with: "")
                .replacingOccurrences(of: "/", with: "")
            
            // Check if normalized names match closely
            if normalizedSearch.contains(normalizedModelName) || normalizedModelName.contains(normalizedSearch) {
                return (model.isReasoningModel, model.isVision)
            }
        }
        
        return (false, false)
    }
}

// MARK: - Model Row Views

struct LocalModelRow: View {
    
    let modelFile: ModelManager.ModelFile
    let isSelected: Bool
    let isRemoteServerReachable: Bool
    let isReasoning: Bool
    let isVision: Bool
    let onSelect: () -> Void
    
    var shouldHighlight: Bool {
        isSelected && !isRemoteServerReachable
    }
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 8) {
                Text(modelFile.name)
                    .font(.body)
                    .foregroundStyle(.primary)
                Spacer()
                
                HStack(spacing: 6) {
                    if shouldHighlight {
                        Image(systemName: "checkmark")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.accentColor)
                    }
                    if isReasoning {
                        Image(systemName: "brain")
                            .font(.caption)
                            .foregroundStyle(.purple)
                    }
                    if isVision {
                        Image(systemName: "eye")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    shouldHighlight ? Color.accentColor.opacity(0.25) : Color.clear
                )
        )
    }
}

struct RemoteModelRow: View {
    
    let modelName: String
    let isSelected: Bool
    let isRemoteServerReachable: Bool
    let isReasoning: Bool
    let isVision: Bool
    let onSelect: () -> Void
    
    var shouldHighlight: Bool {
        isSelected && isRemoteServerReachable
    }
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 8) {
                Text(modelName)
                    .font(.body)
                    .foregroundStyle(.primary)
                Spacer()
                
                HStack(spacing: 6) {
                    if shouldHighlight {
                        Image(systemName: "checkmark")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.accentColor)
                    }
                    if isReasoning {
                        Image(systemName: "brain")
                            .font(.caption)
                            .foregroundStyle(.purple)
                    }
                    if isVision {
                        Image(systemName: "eye")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    shouldHighlight ? Color.accentColor.opacity(0.25) : Color.clear
                )
        )
    }
}
