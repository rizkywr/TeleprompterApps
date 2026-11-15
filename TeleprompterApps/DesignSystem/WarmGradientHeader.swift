import SwiftUI

struct WarmGradientHeader<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Smooth, seamless ambient radial glow that diffuses into canvas with zero edge boundary
            RadialGradient(
                colors: [
                    AppTheme.lightBlue.opacity(0.32),
                    AppTheme.lightBlue.opacity(0.14),
                    AppTheme.canvas.opacity(0)
                ],
                center: .topLeading,
                startRadius: 20,
                endRadius: 420
            )
            .ignoresSafeArea()
            
            // Content
            content
        }
    }
}
