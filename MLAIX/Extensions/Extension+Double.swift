//
//  Extension+Double.swift
//  MLAI
//
//  Created by John Bean on 2/24/25.
//

import Foundation

public extension Double {
	
	/// The normalized sigmoid value of the `Double` value
	var sigmoid: Double {
		return 1 / (1 + Darwin.exp(-self))
	}
	
}
