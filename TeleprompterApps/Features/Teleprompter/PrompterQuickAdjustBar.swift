import SwiftUI

struct PrompterQuickAdjustBar: View {
    @ObservedObject var viewModel: TeleprompterViewModel
    @State private var isCollapsed: Bool = false
    
    var body: some View {
        Group {
            if isCollapsed {
                // Minimized Pill (Tap to reveal full sliders anytime)
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        isCollapsed = false
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AppTheme.lightBlue)
                        
                        Text("Speed \(Int(viewModel.scrollSpeed))")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        
                        Text("•")
                            .foregroundColor(.white.opacity(0.35))
                        
                        Text("Font \(Int(viewModel.fontSize))pt")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        
                        Text("•")
                            .foregroundColor(.white.opacity(0.35))
                        
                        Text("Line \(Int(viewModel.lineSpacing))pt")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        
                        Circle()
                            .fill(viewModel.textColor.color)
                            .frame(width: 8, height: 8)
                            .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 0.5))
                        
                        Image(systemName: "chevron.up")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.60))
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Color.white.opacity(0.20), lineWidth: 0.8)
                    )
                    .shadow(color: Color.black.opacity(0.35), radius: 6, x: 0, y: 2)
                }
                .transition(.scale(scale: 0.85).combined(with: .opacity))
            } else {
                // Direct Intuitive Dual-Slider Glass Panel (Shown directly on Record View)
                VStack(spacing: 7) {
                    // Header with Quick Label & Minimize button
                    HStack {
                        Text("PROMPTER ADJUST")
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .tracking(1.0)
                            .foregroundColor(AppTheme.lightBlue)
                        
                        Spacer()
                        
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                                isCollapsed = true
                            }
                        } label: {
                            HStack(spacing: 3) {
                                Text("Hide")
                                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 8, weight: .bold))
                            }
                            .foregroundColor(.white.opacity(0.55))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.08), in: Capsule())
                        }
                    }
                    .padding(.horizontal, 2)
                    
                    // Row 1: Scrolling Speed Slider
                    HStack(spacing: 8) {
                        HStack(spacing: 5) {
                            Image(systemName: "speedometer")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AppTheme.lightBlue)
                            Text("Speed")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.85))
                        }
                        .frame(width: 54, alignment: .leading)
                        
                        Slider(value: $viewModel.scrollSpeed, in: 10...100, step: 1)
                            .tint(AppTheme.lightBlue)
                        
                        Text("\(Int(viewModel.scrollSpeed))")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .frame(width: 28, alignment: .trailing)
                    }
                    
                    // Row 2: Font Size Slider
                    HStack(spacing: 8) {
                        HStack(spacing: 5) {
                            Image(systemName: "textformat.size")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AppTheme.lightBlue)
                            Text("Font")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.85))
                        }
                        .frame(width: 54, alignment: .leading)
                        
                        Slider(value: $viewModel.fontSize, in: 16...60, step: 1)
                            .tint(AppTheme.lightBlue)
                        
                        Text("\(Int(viewModel.fontSize))pt")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .frame(width: 32, alignment: .trailing)
                    }
                    
                    // Row 3: Line Spacing Slider (Jarak antara kalimat 1 ke kalimat selanjutnya)
                    HStack(spacing: 8) {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.up.and.down.text.horizontal")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AppTheme.lightBlue)
                            Text("Line")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.85))
                        }
                        .frame(width: 54, alignment: .leading)
                        
                        Slider(value: $viewModel.lineSpacing, in: 4...36, step: 1)
                            .tint(AppTheme.lightBlue)
                        
                        Text("\(Int(viewModel.lineSpacing))pt")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .frame(width: 32, alignment: .trailing)
                    }
                    
                    // Row 4: Color Palette Picker
                    HStack(spacing: 8) {
                        HStack(spacing: 5) {
                            Image(systemName: "paintpalette.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AppTheme.lightBlue)
                            Text("Color")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.85))
                        }
                        .frame(width: 54, alignment: .leading)
                        
                        HStack(spacing: 10) {
                            ForEach(PrompterTextColor.allCases) { item in
                                Button {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    viewModel.textColor = item
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(item.color)
                                            .frame(width: 18, height: 18)
                                        
                                        if viewModel.textColor == item {
                                            Circle()
                                                .stroke(Color.white, lineWidth: 2)
                                                .frame(width: 22, height: 22)
                                        }
                                    }
                                    .frame(width: 24, height: 24)
                                }
                            }
                        }
                        
                        Spacer()
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .frame(maxWidth: 320)
                .background(Color.black.opacity(0.62))
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 0.8)
                )
                .shadow(color: Color.black.opacity(0.45), radius: 10, x: 0, y: 3)
                .transition(.scale(scale: 0.95).combined(with: .opacity))
            }
        }
    }
}
