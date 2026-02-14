//
//  CompletionsSetupViewModel.swift
//  MLAI
//
//  Created by John Bean on 3/25/25.
//

import Foundation
import Observation
import SwiftUI

@MainActor
@Observable public class CompletionsSetupViewModel {
	
	public var step: Step = .nextTokenTutorial
	
	public enum Step: CaseIterable {
		case nextTokenTutorial
		case allTokensTutorial
		case downloadModel
		case done
	}
	
}
