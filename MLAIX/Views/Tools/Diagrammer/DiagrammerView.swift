//
//  DiagrammerView.swift
//  MLAI
//
//  Created by John Bean on 2/20/25.
//

import SwiftUI

struct DiagrammerView: View {
	
	@Environment(Model.self) private var model
	@State private var diagrammerViewController: DiagrammerViewController = .init()
	
    var body: some View {
		Group {
			switch self.diagrammerViewController.currentStep {
				case .prompt:
					DiagrammerPromptView()
				case .generating:
					DiagrammerGeneratingView()
				case .editAndPreview:
					DiagrammerPreviewEditorView()
			}
		}
		.environment(diagrammerViewController)
    }
	
}
