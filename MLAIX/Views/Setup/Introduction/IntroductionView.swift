//
//  IntroductionView.swift
//  MLAI
//
//  Created by Bean John on 9/23/24.
//

import SwiftUI

struct IntroductionView: View {
    
    @Environment(ConversationState.self) private var conversationState
    
    @State private var introductionViewController: IntroductionViewController = .init()
    
    @Binding var showSetup: Bool
    
    var body: some View {
        Group {
            switch introductionViewController.page {
                case .done:
                    SetupCompleteView(
                        description: String(localized: "MLAI is ready to use.")
                    ) {
                        Settings.finishSetup()
                        self.showSetup = false
                    }
                    .frame(maxHeight: 400)
                    .padding(.horizontal)
                default:
                    page
            }
        }
        .frame(maxHeight: 600)
        .environment(introductionViewController)
    }
    
    var page: some View {
        VStack {
            HStack {
                introductionViewController.prevPage
                VStack {
			if let content = introductionViewController.page.content {
				IntroductionPageView(
					content: content
				)
				.padding()
			}
                    // Progress indicator
                    if introductionViewController.page.hasNext {
                        introductionViewController.progress
                    }
                }
                introductionViewController.nextPage
            }
            .padding(.horizontal)
            Divider()
            HStack {
                Spacer()
                Button {
                    Settings.finishSetup()
                    self.showSetup = false
                } label: {
                    Text("Skip")
                }
                .buttonStyle(.link)
            }
            .padding(.horizontal)
            .padding(.top, 3)
            .padding(.bottom)
        }
    }

}
