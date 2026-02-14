//
//  AppState.swift
//  MLAI
//
//  Created by Bean John on 11/5/24.
//

import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
public class AppState {
	
	static let shared: AppState = AppState()
	
	var commandSelectedExpertId: UUID? = nil
	
	static func setCommandSelectedExpertId(_ id: UUID) {
		Self.shared.commandSelectedExpertId = id
	}
	
}
