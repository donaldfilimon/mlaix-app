//
//  DiagrammerPreviewEditorView.swift
//  MLAI
//
//  Created by John Bean on 2/20/25.
//

import SwiftUI
@preconcurrency import CodeEditorView
import LanguageSupport

struct DiagrammerPreviewEditorView: View {
	
	@Environment(\.dismissWindow) private var dismissWindow
	@Environment(\.colorScheme) private var colorScheme: ColorScheme
	@EnvironmentObject private var diagrammerViewController: DiagrammerViewController
	
	@State private var position: CodeEditor.Position = CodeEditor.Position()
	@State private var messages: Set<TextLocated<LanguageSupport.Message>> = Set()
	
	@State private var previewId: UUID = UUID()
	
	private var refreshButtonSymbolName: String { "arrow.trianglehead.counterclockwise" }
	
    var body: some View {
		HSplitView {
			editor
				.frame(minWidth: 300)
			ZStack {
				Rectangle()
					.fill(Color.clear)
					.frame(width: 1)
					.frame(maxHeight: .infinity)
                ZoomablePannableView {
                    self.diagrammerViewController.preview
                        .id(previewId)
                }
                .overlay(alignment: .topTrailing) {
                    refreshButton
                        .padding([.top, .trailing], 6)
                }
			}
			.frame(minWidth: 300)
		}
		.toolbar {
			ToolbarItemGroup(
				placement: .primaryAction
			) {
				newButton
				saveButton
				exitButton
			}
		}
    }
	
	/// The code editor theme based on the current color scheme
	private var editorTheme: Theme {
		// Access the static properties on the main actor to satisfy concurrency requirements
		nonisolated(unsafe) let darkTheme = Theme.defaultDark
		nonisolated(unsafe) let lightTheme = Theme.defaultLight
		return colorScheme == .dark ? darkTheme : lightTheme
	}

	var editor: some View {
		CodeEditor(
            text: self.$diagrammerViewController.mermaidCode,
			position: self.$position,
			messages: self.$messages
		)
		.environment(
			\.codeEditorTheme, editorTheme
		)
		.onChange(of: diagrammerViewController.mermaidCode) { _, _ in
            Task { @MainActor in
                try? await self.diagrammerViewController.render(
                    attemptsRemaining: 0
                )
            }
        }
	}
	
	var saveButton: some View {
		Button {
			self.saveDiagram()
		} label: {
			Text("Save")
		}
		.keyboardShortcut("s", modifiers: [.command])
		.controlSize(.large)
	}
	
	var newButton: some View {
		Button {
			// Reset to exit to prompt view
			self.resetDiagram()
		} label: {
			Text("New Diagram")
		}
	}
	
	var exitButton: some View {
		Button {
			// Reset
			self.resetDiagram()
			// Close window
			self.dismissWindow(id: "diagrammer")
		} label: {
			Text("Exit")
		}
		.controlSize(.large)
	}
	
	var refreshButton: some View {
		Button {
			// Restart server
            Task { @MainActor in
                try? await self.diagrammerViewController.render(attemptsRemaining: 0)
                // Reset id to redraw view
                self.previewId = UUID()
            }
		} label: {
			Label("Refresh", systemImage: refreshButtonSymbolName)
				.labelStyle(.iconOnly)
				.foregroundStyle(Color.white)
		}
		.buttonStyle(.plain)
		.padding([.horizontal, .bottom], 8)
		.padding(.top, 7)
		.background {
			Circle()
				.fill(Color(nsColor: .darkGray))
		}
	}
	
	private func resetDiagram() {
		self.diagrammerViewController.mermaidCode = ""
        MermaidRenderer.resetMermaidCode()
		self.diagrammerViewController.currentStep = .prompt
	}
	
	private func saveDiagram() {
		// Save image
		let saveSuccess: Bool = self.diagrammerViewController.saveImage()
		let message: String = saveSuccess ? String(localized: "Diagram saved successfully") : String(localized: "Failed to save diagram")
		// Show dialog
		Dialogs.showAlert(
			title: String(localized: "Save"),
			message: message
		)
	}
	
}
