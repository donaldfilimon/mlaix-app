//
//  ModelNameMenu.swift
//  MLAI
//
//  Created by John Bean on 3/21/25.
//

import SwiftUI

struct ModelNameMenu: View {
    
    var modelType: ModelType = .regular
    var modelTypes: [ModelSource]
    
    @AppStorage("endpoint") private var serverEndpoint: String = InferenceSettings.endpoint
    
    @Binding var serverModelName: String
    @AppStorage("serverModelHasVision") private var serverModelHasVision: Bool = InferenceSettings.serverModelHasVision
    
    @State private var remoteModelNames: [String] = []
    @State private var customModelNames: [String] = InferenceSettings.customModelNames
    @State private var isManagingCustomModel: Bool = false
    
    @State private var localModelsListId: UUID = UUID()
    @Environment(ModelManager.self) private var modelManager
    
    var showLocal: Bool {
        return modelTypes.contains(.local) && !modelManager.models.isEmpty
    }
    
    var showSpeculative: Bool {
        return modelTypes.contains(.localSpeculative) && !modelManager.models.isEmpty
    }
    
    var showRemote: Bool {
        return modelTypes.contains(.remote)
    }
    
    var body: some View {
        menu
            .sheet(
                isPresented: self.$isManagingCustomModel
            ) {
                CustomModelsEditor(
                    customModelNames: self.$customModelNames,
                    isPresented: self.$isManagingCustomModel
                )
                .frame(minWidth: 400)
            }
            .task {
                await self.refreshModelNames()
            }
            .onChange(of: serverEndpoint) { _, _ in
                Task { @MainActor in
                    await self.refreshModelNames()
                }
            }
            .onChange(of: NavigationState.shared.inferenceConfigChanged) { _, _ in
                // Refresh selection
                self.localModelsListId = UUID()
            }
            .onChange(of: self.serverModelName) { _, _ in
                // If is worker mode, return
                if self.modelType == .worker {
                    return
                }
                // Turn has vision on if model is in list and is multimodal
                let serverModelHasVision: Bool =  KnownModel.availableModels.contains { model in
                    let nameMatches: Bool = self.serverModelName.contains(model.primaryName)
                    return nameMatches && model.isVision
                }
                self.serverModelHasVision = serverModelHasVision
            }
    }
    
    var menu: some View {
        Menu {
            if showLocal {
                localModelsList
            }
            if showLocal && (showSpeculative || showRemote) {
                Divider()
            }
            if showSpeculative {
                localSpeculativeModelsList
            }
            if showSpeculative && showRemote {
                Divider()
            }
            if showRemote {
                remoteModelsList
            }
        } label: {
            if self.modelTypes == [.remote] {
                Text(
                    self.serverModelName.isEmpty
                    ? String(localized: "No Model Selected")
                    : ModelNameFormatter.formatModelName(self.serverModelName)
                )
            } else {
                Label("Model", systemImage: "brain")
            }
        }
    }
    
    var localModelsList: some View {
        Group {
            Text("Local Models")
                .bold()
            ForEach(sortedLocalModels, id: \.name) { model in
                LocalModelButton(
                    modelFile: model
                )
            }
        }
        .id(localModelsListId)
    }
    
    var sortedLocalModels: [ModelManager.ModelFile] {
        modelManager.models.sorted { model1, model2 in
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
    
    var localSpeculativeModelsList: some View {
        Group {
            Text("Draft Models")
                .bold()
            ForEach(sortedLocalModels, id: \.name) { model in
                LocalModelButton(
                    modelFile: model,
                    isSelectingSpeculative: true
                )
            }
            .disabled(!InferenceSettings.useSpeculativeDecoding)
            if self.modelTypes != [.localSpeculative] {
                Divider()
                Button {
                    InferenceSettings.useSpeculativeDecoding.toggle()
                    // Signal inference config change
                    NavigationState.shared.inferenceConfigChanged = true
                } label: {
                    if InferenceSettings.useSpeculativeDecoding {
                        Text("Disable Speculative Decoding")
                    } else {
                        Text("Use Speculative Decoding")
                    }
                }
            }
        }
        .id(localModelsListId)
    }
    
    var remoteModelsList: some View {
        Group {
            Text("Remote Models")
                .bold()
            // Show API & custom models sorted by parameter count
            ForEach(
                (remoteModelNames + customModelNames).sortedByModelSize(),
                id: \.self
            ) { modelName in
                RemoteModelButton(
                    serverModelName: self.$serverModelName,
                    modelName: modelName
                )
            }
            .disabled(!InferenceSettings.useServer && modelTypes != [.remote])
            if !(remoteModelNames + customModelNames).isEmpty {
                Divider()
            }
            remoteModelOptions
        }
    }
    
    var remoteModelOptions: some View {
        Group {
            Button {
                self.isManagingCustomModel = true
            } label: {
                Text("Manage Custom Models")
            }
            .disabled(!InferenceSettings.useServer && modelTypes != [.remote])
            if self.modelTypes != [.remote] {
                Button {
                    InferenceSettings.useServer.toggle()
                    // Signal inference config change
                    NavigationState.shared.inferenceConfigChanged = true
                } label: {
                    if InferenceSettings.useServer {
                        Text("Disable Remote Model")
                    } else {
                        Text("Use Remote Model")
                    }
                }
            }
        }
    }
    
    private func refreshModelNames() async {
        self.remoteModelNames = await LlamaServer.getAvailableModels()
    }
    
    enum ModelSource: CaseIterable {
        case local, localSpeculative, remote
    }
    
    struct LocalModelButton: View {
        
        var modelFile: ModelManager.ModelFile
        var isSelectingSpeculative: Bool = false
        
        var body: some View {
            Button {
                self.select()
            } label: {
                let modelUrl: URL? = isSelectingSpeculative ? InferenceSettings.speculativeDecodingModelUrl : Settings.modelUrl
                if modelUrl == self.modelFile.url {
                    Label(modelFile.name, systemImage: "checkmark")
                        .labelStyle(.titleAndIcon)
                        .bold()
                } else {
                    Text(modelFile.name)
                }
            }
        }
        
        private func select() {
            // Set
            if !isSelectingSpeculative {
                Settings.modelUrl = modelFile.url
            } else {
                InferenceSettings.speculativeDecodingModelUrl = modelFile.url
            }
            // Signal inference config change
            NavigationState.shared.inferenceConfigChanged = true
        }
        
    }
    
    struct RemoteModelButton: View {
        
        @Binding var serverModelName: String
        var modelName: String
        
        var body: some View {
            Button {
                self.serverModelName = modelName
                // Signal inference config change
                NavigationState.shared.inferenceConfigChanged = true
            } label: {
                if modelName == serverModelName {
                    Label(
                        ModelNameFormatter.formatModelName(modelName),
                        systemImage: "checkmark"
                    )
                        .labelStyle(.titleAndIcon)
                        .bold()
                } else {
                    Text(ModelNameFormatter.formatModelName(modelName))
                }
            }
        }
        
    }
    
    struct CustomModelsEditor: View {
        
        @Binding var customModelNames: [String]
        @Binding var isPresented: Bool
        
        var body: some View {
            VStack(
                alignment: .leading
            ) {
                List(
                    self.$customModelNames,
                    id: \.self
                ) { modelName in
                    HStack {
                        CustomModelsEditorField(modelName: modelName)
                        Spacer()
                        Button {
                            // Remove from list
                            withAnimation(.linear) {
                                self.customModelNames = self.customModelNames.filter { name in
                                    return name != modelName.wrappedValue
                                }
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                                .foregroundStyle(.red)
                                .labelStyle(.iconOnly)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(minHeight: 200, maxHeight: 300)
                Divider()
                HStack {
                    Spacer()
                    addButton
                    doneButton
                }
                .controlSize(.large)
                .padding([.bottom, .trailing], 12)
            }
            .onDisappear {
                withAnimation(.linear) {
                    // Filter and save
                    self.filterAndSaveModels()
                }
            }
        }
        
        var addButton: some View {
            Button {
                // Add
                withAnimation(.linear) {
                    self.customModelNames.append("")
                }
            } label: {
                Text("Add")
            }
        }
        
        var doneButton: some View {
            Button {
                // Filter and save
                self.filterAndSaveModels()
                // Hide sheet
                self.isPresented.toggle()
            } label: {
                Text("Done")
            }
            .keyboardShortcut(.defaultAction)
        }
        
        /// Function to filter out blank model names
        private func filterAndSaveModels() {
            // Keep unique names
            self.customModelNames = Array(Set(self.customModelNames)).sorted()
            // Filter out blank model names
            self.customModelNames = self.customModelNames.filter { name in
                return !name.isEmpty
            }
            // Save
            InferenceSettings.customModelNames = self.customModelNames
        }
        
        struct CustomModelsEditorField: View {
            
            init(modelName: Binding<String>) {
                self._modelName = modelName
                self.name = modelName.wrappedValue
            }
            
            @Binding var modelName: String
            @State private var name: String
            @FocusState    private var isFocused: Bool
            
            var body: some View {
                TextField("", text: self.$name)
                    .focused(self.$isFocused)
                    .textFieldStyle(.plain)
                    .onChange(of: isFocused) { _, newValue in
                        if newValue {
                            name = modelName
                        } else {
                            modelName = name
                        }
                    }
                    .onSubmit {
                        modelName = name
                    }
            }
            
        }
        
    }
    
}
