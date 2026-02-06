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

    @State private var statusMessage: String = "Select a CSV dataset or train from self-learning data."
    @State private var isTraining: Bool = false

    private var collectedCount: Int { TrainingDataCollector.collectedSampleCount }

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
            if collectedCount > 0 {
                Text("\(collectedCount) samples from user choices and conversations")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                Spacer()
                Button("Export from Conversations") {
                    Task { @MainActor in
                        await exportFromConversations()
                    }
                }
                .disabled(isTraining || ConversationManager.shared.conversations.isEmpty)
                Button("Train from Collected") {
                    Task { @MainActor in
                        await trainFromCollected()
                    }
                }
                .disabled(isTraining || collectedCount < 10)
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
    private func exportFromConversations() async {
        let samples = TrainingDataCollector.exportFromConversations(ConversationManager.shared.conversations)
        TrainingDataCollector.appendExportedSamples(samples)
        statusMessage = "Exported \(samples.count) samples from conversations. Total: \(TrainingDataCollector.collectedSampleCount)."
    }

    @MainActor
    private func trainFromCollected() async {
        isTraining = true
        statusMessage = "Training from collected data..."
        do {
            if let modelUrl = try await CoreMLTrainer.trainFromCollectedData() {
                promptClassifierUrl = modelUrl
                statusMessage = "Training complete: \(modelUrl.lastPathComponent)"
            } else {
                statusMessage = "No collected data. Use Text/Image choices or export from conversations first."
            }
        } catch {
            statusMessage = error.localizedDescription
        }
        isTraining = false
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
