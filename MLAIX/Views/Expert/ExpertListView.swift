//
//  ExpertListView.swift
//  MLAI
//
//  Created by Bean John on 10/10/24.
//

import SwiftUI

struct ExpertListView: View {
	
	@Environment(ExpertManager.self) private var expertManager
	
    var body: some View {
		@Bindable var expertManager = expertManager
		return List(
			$expertManager.experts,
			editActions: .move
		) { expert in
			ExpertNavigationRowView(
				expert: expert
			)
			.listRowSeparator(.hidden)
		}
    }
	
}
