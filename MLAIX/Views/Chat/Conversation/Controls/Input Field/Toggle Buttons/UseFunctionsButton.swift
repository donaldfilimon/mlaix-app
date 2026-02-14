//
//  UseFunctionsButton.swift
//  MLAI
//
//  Created by John Bean on 4/14/25.
//

import SwiftUI

struct UseFunctionsButton: View {
    
    @Environment(PromptController.self) private var promptController
    var functionSelectionManager = FunctionSelectionManager.shared
    
    var activatedFillColor: Color
    
    @Binding var useFunctions: Bool
    
    var useFunctionsTip: UseFunctionsTip = .init()
    
    var body: some View {
        CapsuleChecklistMenuButton(
            label: String(localized: "Functions"),
            systemImage: "function",
            activatedFillColor: activatedFillColor,
            isActivated: self.$useFunctions,
            functionSelectionManager: functionSelectionManager
        ) { newValue in
            self.onToggle(newValue: newValue)
        }
        .popoverTip(self.useFunctionsTip)
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
            self.useFunctions = false
            Dialogs.showAlert(
                title: String(localized: "Functions Unavailable"),
                message: String(
                    localized: "Functions require a local or remote model. Configure one in Settings or disable Apple Foundation Models."
                )
            )
            return
        }
        // Check if functions is configured
        if !Settings.useFunctions {
            // If not, show error and return
            self.useFunctions = false // Set back to false
            Dialogs.showAlert(
                title: String(localized: "Functions Disabled"),
                message: String(localized: "Functions are disabled in Settings. Please configure it in \"Settings\" -> \"General\" -> \"Functions\".")
            )
            return
        }
        // Check if deep research is activated
        if self.promptController.isUsingDeepResearch {
            // If true, force functions
            self.useFunctions = true
            Dialogs.showAlert(
                title: String(localized: "Not Available"),
                message: String(localized: "Functions must be turned on to use Deep Research.")
            )
            return
        }
    }
    
}
