//
//  ThemePreset.swift
//  MLAIXShared
//

import SwiftUI

/// Shared theme presets for accent color (iOS, macOS).
public enum ThemePreset: String, CaseIterable, Identifiable {
    case `default`
    case ocean
    case forest
    case sunset
    case lavender
    case rose

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .default: return "Default"
        case .ocean: return "Ocean"
        case .forest: return "Forest"
        case .sunset: return "Sunset"
        case .lavender: return "Lavender"
        case .rose: return "Rose"
        }
    }

    public var accentHex: String {
        switch self {
        case .default: return "007AFFFF"
        case .ocean: return "0E7AF0FF"
        case .forest: return "22C55EFF"
        case .sunset: return "F97316FF"
        case .lavender: return "8B5CF6FF"
        case .rose: return "EC4899FF"
        }
    }
}
