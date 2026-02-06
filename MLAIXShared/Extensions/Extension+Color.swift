//
//  Extension+Color.swift
//  MLAIXShared
//

import SwiftUI

public extension Color {
    /// Parse hex string (e.g. "RRGGBBAA" or "101828FF").
    init(hex: String) {
        let rgba = hex.toRGBA()
        self.init(
            .sRGB,
            red: Double(rgba.r),
            green: Double(rgba.g),
            blue: Double(rgba.b),
            opacity: Double(rgba.alpha)
        )
    }

    /// Hex representation (RRGGBBAA).
    var toHex: String? {
        let env = EnvironmentValues()
        let r = resolve(in: env).red
        let g = resolve(in: env).green
        let b = resolve(in: env).blue
        let a = resolve(in: env).opacity
        return String(format: "%02lX%02lX%02lX%02lX",
                      lroundf(r * 255), lroundf(g * 255),
                      lroundf(b * 255), lroundf(a * 255))
    }
}

extension String {
    fileprivate func toRGBA() -> (r: CGFloat, g: CGFloat, b: CGFloat, alpha: CGFloat) {
        var hex = trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        if hex.count == 6 { hex += "FF" }
        if hex.count == 8 {
            var rgb: UInt64 = 0
            Scanner(string: hex).scanHexInt64(&rgb)
            return (
                CGFloat((rgb >> 24) & 0xFF) / 255,
                CGFloat((rgb >> 16) & 0xFF) / 255,
                CGFloat((rgb >> 8) & 0xFF) / 255,
                CGFloat(rgb & 0xFF) / 255
            )
        }
        return (0, 0, 0, 1)
    }
}
