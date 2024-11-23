import SwiftUI

// MARK: - Color Extension
extension Color {
    static let appTheme = AppTheme()
}

// MARK: - App Theme
struct AppTheme {
    // Primary Colors
    let primaryOrange = Color("PrimaryOrange")
    let primaryGreen = Color("PrimaryGreen")
    
    // Secondary Colors
    let secondaryprimaryBlack = Color("SecondaryprimaryBlack")
    let secondaryYellow = Color("SecondaryYellow")
    
    // Background
    let background = Color("Background")
    
    // Additional Colors for Text and UI Elements
    let textPrimary = Color.black
    let textSecondary = Color.gray
}

// MARK: - Custom View Modifiers
struct AppThemeModifier: ViewModifier {
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    func body(content: Content) -> some View {
        content
            .preferredColorScheme(.light) // Force light mode
            .background(Color.appTheme.background)
    }
}

// MARK: - View Extension
extension View {
    func withAppTheme() -> some View {
        modifier(AppThemeModifier())
    }
}
