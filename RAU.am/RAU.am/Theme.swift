import SwiftUI

/// Colours approximating the university's blue/red identity. Change them here to restyle the whole app.
enum Theme {
    static let navy = Color(hex: 0x14315C)
    static let crimson = Color(hex: 0xB3202A)
    static let heroOverlay = LinearGradient(colors: [.clear, Color.black.opacity(0.75)],
                                            startPoint: .center, endPoint: .bottom)
}

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }
}
