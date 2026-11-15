import SwiftUI

enum AppTypography {
    // HIG Large Title (34pt, Bold, SF Pro Rounded)
    static func largeTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 34, weight: .bold, design: .rounded))
            .foregroundColor(AppTheme.textPrimary)
    }
    
    // HIG Title 1 (28pt, Bold, SF Pro Rounded)
    static func title1(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 28, weight: .bold, design: .rounded))
            .foregroundColor(AppTheme.textPrimary)
    }
    
    // HIG Title 2 (22pt, Bold, SF Pro Rounded)
    static func title2(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 22, weight: .bold, design: .rounded))
            .foregroundColor(AppTheme.textPrimary)
    }
    
    // HIG Title 3 (20pt, Semibold, SF Pro Rounded)
    static func title3(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 20, weight: .semibold, design: .rounded))
            .foregroundColor(AppTheme.textPrimary)
    }
    
    // HIG Headline (17pt, Semibold, SF Pro Rounded)
    static func headline(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .foregroundColor(AppTheme.textPrimary)
    }
    
    // HIG Body (17pt, Regular, SF Pro Rounded)
    static func body(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 17, weight: .regular, design: .rounded))
            .foregroundColor(AppTheme.textSecondary)
    }
    
    // HIG Subheadline (15pt, Regular, SF Pro Rounded)
    static func subheadline(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .regular, design: .rounded))
            .foregroundColor(AppTheme.textSecondary)
    }
    
    // HIG Footnote (13pt, Regular, SF Pro Rounded)
    static func footnote(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .regular, design: .rounded))
            .foregroundColor(AppTheme.textTertiary)
    }
    
    // HIG Caption 1 (12pt, Medium, SF Pro Rounded)
    static func caption(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundColor(AppTheme.textSecondary)
    }
}
