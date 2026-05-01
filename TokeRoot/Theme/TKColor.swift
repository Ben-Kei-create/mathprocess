import SwiftUI

/// Calm, low-saturation palette. Avoids red for "wrong" — even mistakes
/// stay in warm earth tones so the student is never visually scolded.
enum TKColor {
    // Surfaces
    static let background       = Color(.sRGB, red: 0.98, green: 0.98, blue: 0.97, opacity: 1)
    static let surface          = Color(.sRGB, red: 1.00, green: 1.00, blue: 1.00, opacity: 1)
    static let surfaceElevated  = Color(.sRGB, red: 0.96, green: 0.96, blue: 0.94, opacity: 1)
    static let divider          = Color(.sRGB, red: 0.90, green: 0.90, blue: 0.88, opacity: 1)

    // Text
    static let textPrimary      = Color(.sRGB, red: 0.13, green: 0.14, blue: 0.16, opacity: 1)
    static let textSecondary    = Color(.sRGB, red: 0.42, green: 0.43, blue: 0.46, opacity: 1)
    static let textTertiary     = Color(.sRGB, red: 0.62, green: 0.63, blue: 0.66, opacity: 1)

    // Accents
    static let accent           = Color(.sRGB, red: 0.27, green: 0.50, blue: 0.66, opacity: 1) // muted blue
    static let accentSoft       = Color(.sRGB, red: 0.86, green: 0.92, blue: 0.97, opacity: 1)
    static let success          = Color(.sRGB, red: 0.40, green: 0.62, blue: 0.45, opacity: 1) // sage
    static let successSoft      = Color(.sRGB, red: 0.88, green: 0.94, blue: 0.88, opacity: 1)
    static let warm             = Color(.sRGB, red: 0.78, green: 0.55, blue: 0.36, opacity: 1) // warm amber, used for "惜しい"
    static let warmSoft         = Color(.sRGB, red: 0.97, green: 0.91, blue: 0.84, opacity: 1)
    static let highlight        = Color(.sRGB, red: 0.99, green: 0.92, blue: 0.62, opacity: 1) // gentle yellow
}
