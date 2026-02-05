//
//  CoreMLClassifierPickerView.swift
//  MLAI
//
//  Created by Codex on 2/5/26.
//

import FSKit_macOS
import SwiftUI

struct CoreMLClassifierPickerView: View {
    
    @Binding var isPresented: Bool
    @Binding var promptClassifierUrl: URL?
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Select a Core ML classifier")
                .font(.title2)
                .bold()
            Text("Choose a `.mlmodel` or `.mlmodelc` file. The model should output labels compatible with `text-generation` and `image-generation`.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                Spacer()
                Button("Choose Model") {
                    if let urls = try? FileManager.selectFile(
                        dialogTitle: String(localized: "Select a Core ML model"),
                        canSelectDirectories: false,
                        allowedContentTypes: Settings.coreMLContentTypes,
                        allowMultipleSelection: false,
                        persistPermissions: true
                    ), let url = urls.first {
                        promptClassifierUrl = url
                    }
                    isPresented = false
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.top, 8)
        }
        .padding()
    }
}

#Preview {
    CoreMLClassifierPickerView(
        isPresented: .constant(true),
        promptClassifierUrl: .constant(nil)
    )
}
