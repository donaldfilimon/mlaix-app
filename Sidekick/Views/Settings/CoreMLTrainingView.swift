//
//  CoreMLTrainingView.swift
//  MLAI
//
//  Created by Codex on 2/5/26.
//

import FSKit_macOS
import SwiftUI

struct CoreMLTrainingView: View {
    
    @Binding var isPresented: Bool
    @Binding var promptClassifierUrl: URL?
    
    @State private var statusMessage: String = "Select a CSV dataset with `text` and `label` columns."
    @State private var isTraining: Bool = false
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Train a Core ML classifier")
                .font(.title2)
                .bold()
            Text(statusMessage)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if isTraining {
                ProgressView()
            }
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                Spacer()
                Button("Select CSV & Train") {
                    Task { @MainActor in
                        await trainFromCsv()
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(isTraining)
            }
        }
        .padding()
    }
    
    @MainActor
    private func trainFromCsv() async {
        guard let urls = try? FileManager.selectFile(
            dialogTitle: String(localized: "Select CSV dataset"),
            canSelectDirectories: false,
            allowedContentTypes: Settings.trainingDataContentTypes,
            allowMultipleSelection: false,
            persistPermissions: true
        ), let datasetUrl = urls.first else {
            return
        }
        isTraining = true
        statusMessage = "Training..."
        do {
            let modelUrl = try await CoreMLTrainer.trainPromptClassifier(
                from: datasetUrl
            )
            promptClassifierUrl = modelUrl
            statusMessage = "Training complete: \(modelUrl.lastPathComponent)"
        } catch {
            statusMessage = error.localizedDescription
        }
        isTraining = false
    }
}

#Preview {
    CoreMLTrainingView(
        isPresented: .constant(true),
        promptClassifierUrl: .constant(nil)
    )
}
