import SwiftUI

struct EyebrowBadge: View {
    let text: String
    
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .tracking(1.0)
            .foregroundColor(AppTheme.accentDeep)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(AppTheme.accentSoft)
            .clipShape(Capsule())
    }
}
