//
//  LiquidGlassStyle.swift
//  MLAI
//
//  Created by Codex on 2/5/26.
//

import SwiftUI

struct LiquidGlassStyle: Equatable, Sendable {
    
    enum MaterialStyle: String, CaseIterable, Identifiable {
        case ultraThin
        case thin
        case regular
        case thick
        case ultraThick
        
        var id: String { rawValue }
        
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
