//
//  AppearanceSettings.swift
//  MLAI
//

import SwiftUI

/// User-customizable appearance: theme mode, accent color, font scale.
struct AppearanceSettings: Equatable, Sendable {
    enum AppearanceMode: String, CaseIterable, Identifiable {
        case system
        case light
        case dark

        var id: String { rawValue }

        var colorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .light: return .light
            case .dark: return .dark
            }
        }

        var displayName: String {
            switch self {
            case .system: return "System"
            case .light: return "Light"
            case .dark: return "Dark"
            }
        }
    }

    enum FontScale: Double, CaseIterable, Identifiable {
        case compact = 0.9
        case `default` = 1.0
        case large = 1.15

        var id: Double { rawValue }

        var displayName: String {
            switch self {
            case .compact: return "Compact"
            case .default: return "Default"
            case .large: return "Large"
            }
        }
    }

    /// Preset themes for quick apply (tint + highlight for Liquid Glass, accent for UI).
    enum ThemePreset: String, CaseIterable, Identifiable {
        case `default`
        case ocean
        case forest
        case sunset
        case lavender
        case rose

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .default: return "Default"
            case .ocean: return "Ocean"
            case .forest: return "Forest"
            case .sunset: return "Sunset"
            case .lavender: return "Lavender"
            case .rose: return "Rose"
            }
        }

        var tintHex: String {
            switch self {
            case .default: return "101828FF"
            case .ocean: return "0A2E4AFF"
            case .forest: return "0D2818FF"
            case .sunset: return "4A2C2AFF"
            case .lavender: return "2D1B4EFF"
            case .rose: return "3D1F2DFF"
            }
        }

        var highlightHex: String {
            switch self {
            case .default: return "6FE7FFFF"
            case .ocean: return "5BC4E8FF"
            case .forest: return "7ED957FF"
            case .sunset: return "FF9F43FF"
            case .lavender: return "B794F6FF"
            case .rose: return "F472B6FF"
            }
        }

        var accentHex: String {
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

    var appearanceMode: AppearanceMode
    var accentColorHex: String?
    var fontScale: FontScale
    var themePreset: ThemePreset

    static let `default` = AppearanceSettings(
        appearanceMode: .system,
        accentColorHex: nil,
        fontScale: .default,
        themePreset: .default
    )

    var resolvedAccentColor: Color? {
        guard let hex = accentColorHex, !hex.isEmpty else { return nil }
        return Color(hex: hex)
    }

    var effectiveFontScale: Double { fontScale.rawValue }
}

private struct AppearanceSettingsKey: EnvironmentKey {
    static let defaultValue: AppearanceSettings = .default
}

extension EnvironmentValues {
    var appearanceSettings: AppearanceSettings {
        get { self[AppearanceSettingsKey.self] }
        set { self[AppearanceSettingsKey.self] = newValue }
    }
}
