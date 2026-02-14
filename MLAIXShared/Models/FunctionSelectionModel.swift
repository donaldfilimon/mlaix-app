//
//  FunctionSelectionModel.swift
//  MLAIXShared
//

import Foundation
import SwiftData

/// SwiftData model that mirrors the macOS `FunctionSelectionManager` category persistence.
/// Each row represents whether a particular function category (e.g. "Arithmetic", "Web") is enabled.
@Model
public final class FunctionSelectionModel {
    @Attribute(.unique) public var id: UUID

    /// The raw-value name of the function category (e.g. "Arithmetic", "Calendar").
    /// Marked unique so there is at most one row per category.
    @Attribute(.unique) public var categoryName: String

    /// Whether this function category is currently enabled.
    public var isEnabled: Bool

    public init(
        id: UUID = UUID(),
        categoryName: String,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.categoryName = categoryName
        self.isEnabled = isEnabled
    }
}
