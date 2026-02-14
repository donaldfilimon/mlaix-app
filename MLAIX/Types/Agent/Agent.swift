//
//  Agent.swift
//  MLAI
//
//  Created by John Bean on 5/8/25.
//

import Foundation
import Observation
import SwiftUI

public protocol Agent: AnyObject, Observable {
    
    /// A `String` containing the name of the agent
    var name: String { get }
    
    /// A `View` to display agent progress to users
    @MainActor var preview: AnyView { get }
    
    /// Function to begin the agentic loop
    func run() async throws -> LlamaServer.CompleteResponse
    
}
