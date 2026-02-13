//
//  SearchMenuToggleButton.swift
//  MLAI
//
//  Created by John Bean on 5/7/25.
//

import SwiftUI

struct SearchMenuToggleButton: View {
    
    @Environment(PromptController.self) private var promptController
    
    var activatedFillColor: Color
    
    @Binding var useWebSearch: Bool
    @Binding var selectedSearchState: SearchState
    
    var selectedModel: KnownModel? {
        return Model.shared.selectedModel
    }
    
    var body: some View {
        CapsuleMenuButton(
            systemImage: "magnifyingglass",
            activatedFillColor: activatedFillColor,
            isActivated: self.$useWebSearch,
            selectedOption: self.$selectedSearchState
        ) { newValue in
            withAnimation(.linear) {
                self.onToggle(newValue: newValue)
            }
        } onSelectionChange: { newSelection in
            // Check Deep Research availability
            withAnimation(.linear) {
                self.checkDeepResearchAvailability()
            }
        }
    }
    
    private func onToggle(
        newValue: Bool
    ) {
        let hasLocalModel = Settings.modelUrl?.fileExists ?? false
        let hasRemoteModel = InferenceSettings.useServer
        if newValue,
           InferenceSettings.useFoundationModels,
           FoundationModelsSupport.isAvailable,
           !hasLocalModel,
           !hasRemoteModel {
            Dialogs.showAlert(
                title: String(localized: "Search Unavailable"),
                message: String(
                    localized: "Web search requires a local or remote model. Configure one in Settings or disable Apple Foundation Models."
                )
            )
            self.resetSearchState()
            return
        }
        // Check if search is configured
        if !RetrievalSettings.canUseWebSearch {
            // If not, show error and return
            Dialogs.showAlert(
                title: String(localized: "Search not configured"),
                message: String(localized: "Search is not configured properly. Please configure it in \"Settings\" -> \"Retrieval\".")
            )
            // Set back to false
            self.useWebSearch = false
            return
        }
        // Check Deep Research
        self.checkDeepResearchAvailability()
    }
    
    private func checkDeepResearchAvailability() {
        // If not using Deep Research, return
        if !self.promptController.isUsingDeepResearch {
            return
        }
        // Check if function calling is activated
        if !Settings.useFunctions {
            // If not, show error and return
            Dialogs.showAlert(
                title: String(localized: "Not Available"),
                message: String(localized: "Functions must be turned on to use Deep Research.")
            )
            self.resetSearchState()
            return
        } else {
            // If functions can be used, force on
            self.promptController.useFunctions = true
        }
    }
    
    /// Function to reset search state
    private func resetSearchState() {
        self.useWebSearch = false // Set back to false
        self.selectedSearchState = .search
    }
    
}
