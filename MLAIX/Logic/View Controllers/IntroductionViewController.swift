//
//  IntroductionViewController.swift
//  MLAI
//
//  Created by Bean John on 12/15/24.
//

import Foundation
import Observation
import SwiftUI

@MainActor
@Observable public class IntroductionViewController {
	
	var page: IntroductionPage = IntroductionPage.allCases.first!
	
	public var progress: some View {
		HStack {
			ForEach(
				Array(IntroductionPage.allCases.enumerated()),
				id: \.offset
			) { index, _ in
				Circle()
					.frame(width: 7.5)
					.foregroundColor({
						if index == self.page.progress {
							return Color.primary
						}
						return Color.secondary
					}())
			}
		}
	}
	
	public var prevPage: some View {
		Button {
			self.page.prevCase()
		} label: {
			Image(
				systemName: "chevron.left"
			)
			.imageScale(.large)
		}
		.buttonStyle(.plain)
		.keyboardShortcut(.leftArrow)
		.disabled(!page.hasPrev)
	}
	
	public var nextPage: some View {
		Button {
			self.page.nextCase()
		} label: {
			Image(
				systemName: "chevron.right"
			)
			.imageScale(.large)
		}
		.buttonStyle(.plain)
		.keyboardShortcut(.rightArrow)
		.disabled(!page.hasNext)
	}
	
}
