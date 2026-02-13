//
//  DetectorView.swift
//  MLAI
//
//  Created by John Bean on 2/24/25.
//

import SwiftUI

struct DetectorView: View {
	
	@State private var detectorViewController: DetectorViewController = .init()
	@Environment(\.dismissWindow) private var dismissWindow
	
	var body: some View {
		@Bindable var detectorViewController = detectorViewController
		Group {
			switch detectorViewController.state {
				case .input:
					DetectorInputView()
				case .evaluating:
					evaluating
				case .result:
					DetectorEvaluationResultView()
			}
		}
		.inspector(
			isPresented: $detectorViewController.showInspector
		) {
			DetectorResultView()
		}
		.inspectorColumnWidth(
			min: 300,
			ideal: 350,
			max: 400
		)
		.interactiveDismissDisabled(true)
		.toolbar {
			ToolbarItemGroup(
				placement: .primaryAction
			) {
				exitButton
			}
		}
		.environment(detectorViewController)
	}
	
	var evaluating: some View {
		ScrollView {
			HStack {
				Text(detectorViewController.text)
					.font(.title3)
					.textSelection(.enabled)
				Spacer()
			}
			.padding()
		}
	}
	
	var exitButton: some View {
		Button {
			self.detectorViewController.reset()
			self.dismissWindow(id: "detector")
		} label: {
			Text("Exit")
		}
	}
	
}
