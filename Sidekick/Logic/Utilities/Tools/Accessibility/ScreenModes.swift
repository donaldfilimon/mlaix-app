//
//  ScreenCorrectionMode.swift
//  CursorBounds
//
//  Created by Aether on 08/01/2025.
//


import Foundation
import AppKit

public enum ScreenCorrectionMode: Sendable {

    case none              // No correction applied
    case adjustForYAxis    // Apply Y-axis correction

}

public enum BoundsCornerX: Sendable {
    case minX
    case maxX
}

public enum BoundsCornerY: Sendable {
    case minY
    case maxY
}
