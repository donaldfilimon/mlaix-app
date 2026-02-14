//
//  SlideStudioProgressView.swift
//  MLAI
//
//  Created by John Bean on 2/28/25.
//

import SwiftfulLoadingIndicators
import SwiftUI

struct SlideStudioProgressView: View {
	
	@Environment(SlideStudioViewController.self) private var slideStudioViewController
	
    var body: some View {
		VStack(
			spacing: 35
		) {
			OrbView(size: .medium)
			stallingPhrase
		}
    }
	
	var stallingPhrase: some View {
		Text(self.slideStudioViewController.currentStep.stallingPhrase)
			.font(.title)
			.bold()
			.contentTransition(.numericText())
	}
	
}
