//
//  CompletionsSetupViewModel.swift
//  MLAI
//
//  Created by John Bean on 3/25/25.
//

import Foundation
import SwiftUI

@MainActor
public class CompletionsSetupViewModel: ObservableObject {
	
	@Published public var step: Step = .nextTokenTutorial
	
	public enum Step: CaseIterable {
		case nextTokenTutorial
		case allTokensTutorial
		case downloadModel
		case done
	}
	
}
