//
//  Extension+Binding.swift
//  MLAI
//
//  Created by Bean John on 10/11/24.
//

import Foundation
import SwiftUI
import OSLog

@MainActor
extension Binding where Value == TemporaryResource {

    /// Function to scan temporary resource
    func scan() async {
        let _ = await wrappedValue.scan()
    }
}


@MainActor
extension Binding where Value == Expert {

    /// Function to add a resource
    func addResource(_ resource: Resource) async {
        // Create mutable copy
        var expert = wrappedValue
        expert.resources.addResource(resource)
        self.wrappedValue = expert
        ExpertManager.shared.update(expert)
    }

    /// Function to add multiple resources
    func addResources(_ resources: [Resource]) async {
        // Create mutable copy
        var expert = wrappedValue
        expert.resources.addResources(resources)
        self.wrappedValue = expert
        ExpertManager.shared.update(expert)
    }

    /// Function to remove a resource
    func removeResource(_ resource: Resource) async {
        // Create mutable copy
        var expert = wrappedValue
        expert.resources.removeResource(resource)
        self.wrappedValue = expert
        ExpertManager.shared.update(expert)
    }

    /// Function to update a resource index
    func update() async {
        // Create mutable copy
        var expert = wrappedValue
        let expertId = expert.id

        // Update index with progress updates
        await expert.resources.updateResourcesIndex(
            expertName: expert.name,
            progressUpdate: { progress in
                Task { @MainActor in
                    guard var current = ExpertManager.shared.getExpert(id: expertId) else {
                        return
                    }
                    current.resources.graphStatus = .building
                    current.resources.graphProgress = progress
                    ExpertManager.shared.update(current)
                }
            }
        )

        // Write back the modified expert
        self.wrappedValue = expert
        ExpertManager.shared.update(expert)
    }

}
