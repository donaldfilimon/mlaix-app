//
//  SettingsView.swift
//  MLAI
//
//  Created by Bean John on 10/14/24.
//

import SwiftUI

struct SettingsView: View {
	
    var body: some View {
		Group {
			if #available(macOS 15, *) {
				TabView {
					Tab(
						"General",
						systemImage: "gear"
					) {
						GeneralSettingsView()
					}
					Tab(
						"Retrieval",
						systemImage: "magnifyingglass"
					) {
						RetrievalSettingsView()
					}
					Tab(
						"Inference",
						systemImage: "brain.fill"
					) {
						InferenceSettingsView()
					}
					Tab(
						"Appearance",
						systemImage: "paintbrush.fill"
					) {
						AppearanceSettingsView()
					}
					Tab(
						"Deep Research",
						systemImage: "binoculars"
					) {
						DeepResearchSettingsView()
					}
				}
			} else {
				TabView {
					GeneralSettingsView()
						.tabItem {
							Label(
								"General",
								systemImage: "gear"
							)
						}
					RetrievalSettingsView()
						.tabItem {
							Label(
								"Retrieval",
								systemImage: "magnifyingglass"
							)
						}
					InferenceSettingsView()
						.tabItem {
							Label(
								"Inference",
								systemImage: "brain.fill"
							)
						}
					AppearanceSettingsView()
						.tabItem {
							Label(
								"Appearance",
								systemImage: "paintbrush.fill"
							)
						}
					DeepResearchSettingsView()
						.tabItem {
							Label(
								"Deep Research",
								systemImage: "binoculars"
							)
						}
				}
			}
		}
		.frame(maxWidth: 600)
		.liquidGlassPanel(cornerRadius: 18)
		.padding()
    }
	
}
