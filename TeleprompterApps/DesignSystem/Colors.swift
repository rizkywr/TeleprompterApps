import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

enum AppTheme {
    // Exact Palette Tokens from User
    static let boldBlue = Color(hex: "#1E466B")
    static let lightBlue = Color(hex: "#67BAF4")
    static let softWhite = Color(hex: "#FAFAFA")
    static let jetBlack = Color(hex: "#0D0D0D")
    
    // Semantic Tokens
    static let canvas = softWhite                       // #FAFAFA Soft White canvas
    static let surface = Color.white                    // #FFFFFF Pure white cards
    static let surfaceSecondary = Color(hex: "#EEF4F9") // Subtle cool-tinted surface
    
    static let textPrimary = jetBlack                   // #0D0D0D Jet Black text
    static let textSecondary = Color(hex: "#445A6F")    // Rich slate-navy body text
    static let textTertiary = Color(hex: "#879CB0")     // Muted captions & placeholders
    
    static let accent = boldBlue                        // #1E466B Bold Blue primary buttons
    static let accentLight = lightBlue                  // #67BAF4 Light Blue highlights & indicators
    static let accentSoft = Color(hex: "#67BAF4").opacity(0.18) // Soft Light Blue badge background
    static let accentDeep = boldBlue                    // #1E466B High-contrast badge text
    
    static let separator = Color(hex: "#E2E8F0")
    static let recording = Color(hex: "#E53935")
    
    // Hero Gradient Stops (Light Blue to Soft White)
    static let heroGradientStops: [Color] = [
        Color(hex: "#67BAF4"),
        Color(hex: "#A2D4F8"),
        Color(hex: "#D6ECFA"),
        Color(hex: "#FAFAFA")
    ]
}
