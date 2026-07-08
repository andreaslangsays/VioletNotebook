import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Hell"
    case dark = "Dunkel"
    
    var id: String { self.rawValue }
}

struct Theme {
    static func background(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.07, green: 0.05, blue: 0.13) : Color(red: 0.98, green: 0.97, blue: 0.99) // #120d21 / #fbfafc
    }
    
    static func sidebarBackground(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.11, green: 0.08, blue: 0.18) : Color(red: 0.93, green: 0.91, blue: 0.96) // #1c142e / #edebf0
    }
    
    static func cardBackground(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.16, green: 0.12, blue: 0.25) : Color(red: 1.0, green: 1.0, blue: 1.0)
    }
    
    static func accent(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.65, green: 0.40, blue: 0.95) : Color(red: 0.50, green: 0.20, blue: 0.80) // #a855f7 / #8033cc
    }
    
    static func text(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.96, green: 0.95, blue: 0.98) : Color(red: 0.11, green: 0.08, blue: 0.18)
    }
    
    static func textMuted(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.68, green: 0.62, blue: 0.78) : Color(red: 0.45, green: 0.40, blue: 0.55)
    }
    
    static func border(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.22, green: 0.18, blue: 0.35) : Color(red: 0.85, green: 0.82, blue: 0.90) // #382e59 / #d9d1e6
    }
}
