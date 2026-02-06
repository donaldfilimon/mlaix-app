//
//  MLAIXTests.swift
//  MLAIXTests
//
//  Created by Bean John on 10/4/24.
//

import Foundation
import Testing
import DefaultModels
@testable import MLAIX

struct MLAIXTests {

    /// Verifies model recommendations for different hardware configurations.
    @Test func checkModelRecommendations() async throws {
        await DefaultModels.checkModelRecommendations()
    }
}
