import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

enum Tokens {
    static let ink = Color(hex: 0x0B0B10)
    static let paper = Color(hex: 0xF6F2EA)
    static let violet = Color(hex: 0x7C5CFF)
    static let magenta = Color(hex: 0xFF3D9A)
    static let amber = Color(hex: 0xFFB020)
    /// Spectral gradient: reserved for voice and score only.
    static let spectrum = LinearGradient(colors: [violet, magenta, amber], startPoint: .leading, endPoint: .trailing)
}
