import SwiftUI

struct TeleprompterView: View {
    let script: Script
    @ObservedObject var viewModel: TeleprompterViewModel
    
    var body: some View {
        GeometryReader { proxy in
            let isLandscape = proxy.size.width > proxy.size.height
            
            VStack {
                if viewModel.position == .center || viewModel.position == .bottom {
                    Spacer()
                }
                
                // Pure floating prompter container - zero borders, zero background cards
                ZStack {
                    // Optional subtle background only if explicitly enabled in user settings
                    if viewModel.showBackground {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.black.opacity(viewModel.backgroundOpacity))
                            .padding(.horizontal, 4)
                    }
                    
                    // Scrolling Text View with strict bounded vertical wrapping
                    GeometryReader { innerProxy in
                        let cardWidth = innerProxy.size.width
                        let cardHeight = innerProxy.size.height
                        // Bounded reading width for optimal eye movement
                        let contentWidth = min(cardWidth - 28, isLandscape ? 600 : 440)
                        VStack(spacing: 0) {
                            // Top padding so first line aligns comfortably with guide
                            Color.clear
                                .frame(height: viewModel.topPadding)
                            
                            VStack(spacing: 10) {
                                // Script Title Banner inside prompter
                                if !script.title.isEmpty {
                                    Text(script.title.uppercased())
                                        .font(.system(size: max(13, viewModel.fontSize * 0.5), weight: .bold, design: .rounded))
                                        .tracking(1.2)
                                        .foregroundColor(AppTheme.lightBlue)
                                        .shadow(color: .black.opacity(0.95), radius: 5, x: 0, y: 1)
                                        .multilineTextAlignment(.center)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .padding(.bottom, 4)
                                }
                                
                                // Script Text - High contrast shadows for pure floating readability
                                Text(script.content)
                                    .font(.system(size: viewModel.fontSize, weight: .bold, design: .rounded))
                                    .foregroundColor(viewModel.textColor.color)
                                    .multilineTextAlignment(viewModel.textAlignment)
                                    .lineSpacing(viewModel.lineSpacing)
                                    .shadow(color: .black.opacity(0.95), radius: 6, x: 0, y: 2)
                                    .shadow(color: .black.opacity(0.85), radius: 2, x: 0, y: 1)
                            }
                            .frame(width: contentWidth, alignment: alignmentFrom(viewModel.textAlignment))
                            .fixedSize(horizontal: false, vertical: true)
                            .background(
                                GeometryReader { textGeo in
                                    Color.clear.preference(
                                        key: ContentHeightPreferenceKey.self,
                                        value: textGeo.size.height
                                    )
                                }
                            )
                            
                            // Bottom padding so user can scroll to end
                            Color.clear
                                .frame(height: viewModel.bottomPadding)
                        }
                        .frame(width: cardWidth)
                        .offset(y: -viewModel.currentOffset)
                        .scaleEffect(x: viewModel.isMirrored ? -1 : 1, y: 1)
                        .onPreferenceChange(ContentHeightPreferenceKey.self) { height in
                            viewModel.contentHeight = height
                        }
                        .contentShape(Rectangle())
                        // Allow dragging script up and down with finger with natural 1:1 physics & momentum
                        .gesture(
                            DragGesture(minimumDistance: 3)
                                .onChanged { val in
                                    if !viewModel.isDragging {
                                        viewModel.beginDrag()
                                    }
                                    viewModel.updateDrag(translationY: val.translation.height)
                                }
                                .onEnded { val in
                                    viewModel.endDrag(
                                        predictedEndTranslationY: val.predictedEndTranslation.height,
                                        currentTranslationY: val.translation.height
                                    )
                                }
                        )
                    }
                    .clipShape(Rectangle())
                    // Soft fade mask at top and bottom edges so text enters and exits seamlessly
                    .mask(
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0.0),
                                .init(color: .black, location: 0.05),
                                .init(color: .black, location: 0.92),
                                .init(color: .clear, location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    // Minimal sleek reading line indicator aligned with topPadding
                    GeometryReader { _ in
                        HStack {
                            Image(systemName: "arrowtriangle.right.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.yellow)
                                .shadow(color: .black, radius: 4)
                            
                            Spacer()
                            
                            Image(systemName: "arrowtriangle.left.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.yellow)
                                .shadow(color: .black, radius: 4)
                        }
                        .padding(.horizontal, 8)
                        .offset(y: viewModel.topPadding)
                    }
                    .allowsHitTesting(false)
                }
                .frame(maxWidth: .infinity)
                .frame(height: viewModel.windowSize.maxHeight(containerHeight: proxy.size.height, isLandscape: isLandscape))
                .padding(.horizontal, 16)
                
                if viewModel.position == .top || viewModel.position == .center {
                    Spacer()
                }
            }
        }
    }
    
    private func alignmentFrom(_ textAlignment: TextAlignment) -> Alignment {
        switch textAlignment {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }
}

private struct ContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
