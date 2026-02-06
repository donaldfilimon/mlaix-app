//
//  ModelFamily.swift
//  MLAI
//
//  Created by John Bean on 2/18/25.
//

import DefaultModels
import Foundation

/// Note: @unchecked Sendable because HuggingFaceModel (external) lacks Sendable.
/// All properties are value types; thread-safe for read-only sharing.
public struct ModelFamily: Identifiable, Hashable, @unchecked Sendable {
	
	/// Conform to `Identifiable`
	public var id: String { self.name }
	
	/// The name of the model family, in type `String`
	public var name: String
	/// The model's family, in type `HuggingFaceModel.ModelFamily`
	public var family: HuggingFaceModel.ModelFamily
	/// The models in the family, of type `HuggingFaceModel`
	public var models: [HuggingFaceModel]
	
}
