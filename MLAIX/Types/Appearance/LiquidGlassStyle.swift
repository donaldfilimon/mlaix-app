//
//  LiquidGlassStyle.swift
//  MLAI
//
//  Created by Codex on 2/5/26.
//

import SwiftUI

struct LiquidGlassStyle: Equatable, Sendable {

    /// Quick color presets for liquid glass (tint + highlight only).
    enum ColorPreset: String, CaseIterable, Identifiable {
        case `default`
        case frost
        case warm
        case ocean
        case forest
        case midnight
        case sunset
        case lavender

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .default: return String(localized: "Default")
            case .frost: return String(localized: "Frost")
            case .warm: return String(localized: "Warm")
            case .ocean: return String(localized: "Ocean")
            case .forest: return String(localized: "Forest")
            case .midnight: return String(localized: "Midnight")
            case .sunset: return String(localized: "Sunset")
            case .lavender: return String(localized: "Lavender")
            }
        }

        var tintHex: String {
            switch self {
            case .default: return "101828FF"
            case .frost: return "E8F4FCFF"
            case .warm: return "2C2419FF"
            case .ocean: return "0A2E4AFF"
            case .forest: return "0D2818FF"
            case .midnight: return "0F0F23FF"
            case .sunset: return "4A2C2AFF"
            case .lavender: return "2D1B4EFF"
            }
        }

        var highlightHex: String {
            switch self {
            case .default: return "6FE7FFFF"
            case .frost: return "B8E4F8FF"
            case .warm: return "FFD89CFF"
            case .ocean: return "5BC4E8FF"
            case .forest: return "7ED957FF"
            case .midnight: return "6366F1FF"
            case .sunset: return "FF9F43FF"
            case .lavender: return "B794F6FF"
            }
        }
    }

    enum MaterialStyle: String, CaseIterable, Identifiable {
        case ultraThin
        case thin
        case regular
        case thick
        case ultraThick

        var id: String { rawValue }

        var displayName: String {
            rawValue.prefix(1).uppercased() + rawValue.dropFirst()
        }

        @MainActor
        var material: Material {
            switch self {
            case .ultraThin: return .ultraThin
            case .thin: return .thin
            case .regular: return .regular
            case .thick: return .thick
            case .ultraThick: return .ultraThick
            }
        }
    }

    var isEnabled: Bool
    var materialStyle: MaterialStyle
    var tintHex: String
    var highlightHex: String
    var opacity: Double
    var cornerRadius: CGFloat

    @MainActor
    var tintColor: Color {
        Color(hex: tintHex)
    }

    @MainActor
    var highlightColor: Color {
        Color(hex: highlightHex)
    }

    @MainActor
    var material: Material {
        materialStyle.material
    }

    static let `default` = LiquidGlassStyle(
        isEnabled: true,
        materialStyle: .ultraThin,
        tintHex: "101828FF",
        highlightHex: "6FE7FFFF",
        opacity: 0.35,
        cornerRadius: 14
    )
}

private struct LiquidGlassStyleKey: EnvironmentKey {
    static let defaultValue: LiquidGlassStyle = .default
}

extension EnvironmentValues {
    var liquidGlassStyle: LiquidGlassStyle {
        get { self[LiquidGlassStyleKey.self] }
        set { self[LiquidGlassStyleKey.self] = newValue }
    }
}
