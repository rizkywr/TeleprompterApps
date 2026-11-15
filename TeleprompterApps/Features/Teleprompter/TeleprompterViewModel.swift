import SwiftUI
import Combine
import UIKit

enum TeleprompterPosition: String, CaseIterable, Identifiable {
    case top = "Top"
    case center = "Center"
    case bottom = "Bottom"
    
    var id: String { rawValue }
}

enum ScrollDirection: String, CaseIterable, Identifiable {
    case up = "Up"
    case down = "Down"
    
    var id: String { rawValue }
}

enum PrompterTextColor: String, CaseIterable, Identifiable {
    case white = "White"
    case yellow = "Yellow"
    case cyan = "Cyan"
    case green = "Green"
    case orange = "Orange"
    case pink = "Pink"
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        case .white: return .white
        case .yellow: return Color(red: 1.0, green: 0.88, blue: 0.20)
        case .cyan: return AppTheme.lightBlue
        case .green: return Color(red: 0.35, green: 0.95, blue: 0.45)
        case .orange: return Color(red: 1.0, green: 0.62, blue: 0.22)
        case .pink: return Color(red: 1.0, green: 0.45, blue: 0.65)
        }
    }
}


enum PrompterWindowSize: String, CaseIterable, Identifiable {
    case compact = "Compact"
    case standard = "Standard"
    case spacious = "Spacious"
    
    var id: String { rawValue }
    
    func maxHeight(containerHeight: CGFloat, isLandscape: Bool) -> CGFloat {
        if isLandscape {
            switch self {
            case .compact: return min(containerHeight * 0.60, 220)
            case .standard: return min(containerHeight * 0.75, 280)
            case .spacious: return min(containerHeight * 0.88, 350)
            }
        } else {
            switch self {
            case .compact: return min(containerHeight * 0.52, 380)
            case .standard: return min(containerHeight * 0.66, 490)
            case .spacious: return min(containerHeight * 0.80, 600)
            }
        }
    }
}

final class TeleprompterViewModel: ObservableObject {
    // Scrolling State
    @Published var isScrolling: Bool = false
    @Published var currentOffset: CGFloat = 0
    @Published var contentHeight: CGFloat = 0
    
    // Customization Settings
    @Published var scrollSpeed: Double = 40.0 {
        didSet {
            UserDefaults.standard.set(scrollSpeed, forKey: "prompter_scroll_speed")
        }
    }
    @Published var fontSize: CGFloat = 26.0 {
        didSet {
            UserDefaults.standard.set(Double(fontSize), forKey: "prompter_font_size")
        }
    }
    @Published var lineSpacing: CGFloat = 12.0 {
        didSet {
            UserDefaults.standard.set(Double(lineSpacing), forKey: "prompter_line_spacing")
        }
    }
    @Published var textColor: PrompterTextColor = .white {
        didSet {
            UserDefaults.standard.set(textColor.rawValue, forKey: "prompter_text_color")
        }
    }
    @Published var textAlignment: TextAlignment = .center
    @Published var isMirrored: Bool = false
    @Published var position: TeleprompterPosition = .center
    @Published var scrollDirection: ScrollDirection = .up
    @Published var showBackground: Bool = false
    @Published var backgroundOpacity: Double = 0.55
    @Published var windowSize: PrompterWindowSize = .spacious {
        didSet {
            UserDefaults.standard.set(windowSize.rawValue, forKey: "prompter_window_size")
        }
    }
    @Published var topPadding: CGFloat = 80.0 {
        didSet {
            UserDefaults.standard.set(Double(topPadding), forKey: "prompter_top_padding")
        }
    }
    @Published var bottomPadding: CGFloat = 220.0 {
        didSet {
            UserDefaults.standard.set(Double(bottomPadding), forKey: "prompter_bottom_padding")
        }
    }
    
    // Countdown
    @Published var isCountingDown: Bool = false
    @Published var countdownSeconds: Int = 3
    
    private var displayLinkTimer: Timer?
    private var lastUpdateTime: Date?
    private var dragStartOffset: CGFloat = 0
    
    // Natural Drag & Momentum State
    @Published var isDragging: Bool = false
    private var wasScrollingBeforeDrag: Bool = false
    private var resumeWorkItem: DispatchWorkItem?
    
    init() {
        if let savedSpeed = UserDefaults.standard.object(forKey: "prompter_scroll_speed") as? Double, savedSpeed >= 10 && savedSpeed <= 100 {
            self.scrollSpeed = savedSpeed
        }
        if let savedSize = UserDefaults.standard.object(forKey: "prompter_font_size") as? Double, savedSize >= 14 && savedSize <= 65 {
            self.fontSize = CGFloat(savedSize)
        }
        if let savedSpacing = UserDefaults.standard.object(forKey: "prompter_line_spacing") as? Double, savedSpacing >= 2 && savedSpacing <= 50 {
            self.lineSpacing = CGFloat(savedSpacing)
        }
        if let savedColorRaw = UserDefaults.standard.string(forKey: "prompter_text_color"),
           let savedColor = PrompterTextColor(rawValue: savedColorRaw) {
            self.textColor = savedColor
        }
        if let savedWindow = UserDefaults.standard.string(forKey: "prompter_window_size"),
           let size = PrompterWindowSize(rawValue: savedWindow) {
            self.windowSize = size
        }
        if let savedTop = UserDefaults.standard.object(forKey: "prompter_top_padding") as? Double, savedTop >= 10 && savedTop <= 250 {
            self.topPadding = CGFloat(savedTop)
        }
        if let savedBottom = UserDefaults.standard.object(forKey: "prompter_bottom_padding") as? Double, savedBottom >= 30 && savedBottom <= 500 {
            self.bottomPadding = CGFloat(savedBottom)
        }
    }
    
    func increaseSpeed() {
        scrollSpeed = min(100, scrollSpeed + 5)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    func decreaseSpeed() {
        scrollSpeed = max(10, scrollSpeed - 5)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    func increaseFontSize() {
        fontSize = min(60, fontSize + 2)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    func decreaseFontSize() {
        fontSize = max(14, fontSize - 2)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func updateUnifiedPadding(_ newTop: CGFloat) {
        self.topPadding = newTop
        self.bottomPadding = max(100, newTop * 2.6)
    }

    
    func startCountdown(completion: @escaping () -> Void) {
        countdownSeconds = 3
        withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
            isCountingDown = true
        }
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            if self.countdownSeconds > 1 {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
                    self.countdownSeconds -= 1
                }
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            } else {
                timer.invalidate()
                withAnimation(.easeOut(duration: 0.2)) {
                    self.isCountingDown = false
                }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                completion()
            }
        }
    }
    
    func toggleScrolling() {
        if isScrolling {
            pauseScrolling()
        } else {
            resumeScrolling()
        }
    }
    
    func resumeScrolling() {
        guard !isScrolling else { return }
        isScrolling = true
        lastUpdateTime = Date()
        
        displayLinkTimer?.invalidate()
        displayLinkTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }
    
    func pauseScrolling() {
        isScrolling = false
        displayLinkTimer?.invalidate()
        displayLinkTimer = nil
        lastUpdateTime = nil
    }
    
    func restartScript() {
        pauseScrolling()
        currentOffset = 0
    }
    
    func beginDrag() {
        resumeWorkItem?.cancel()
        resumeWorkItem = nil
        
        wasScrollingBeforeDrag = isScrolling
        pauseScrolling()
        isDragging = true
        dragStartOffset = currentOffset
    }
    
    func updateDrag(translationY: CGFloat) {
        let maxScroll = max(0, contentHeight)
        // 1:1 physical tracking: swiping up moves content up
        let rawTarget = dragStartOffset - translationY
        
        if rawTarget < 0 {
            // Smooth iOS rubber-band resistance above top boundary
            currentOffset = rawTarget * 0.35
        } else if rawTarget > maxScroll {
            // Smooth iOS rubber-band resistance below bottom boundary
            currentOffset = maxScroll + (rawTarget - maxScroll) * 0.35
        } else {
            // Exact 1:1 solid finger tracking
            currentOffset = rawTarget
        }
    }
    
    func endDrag(predictedEndTranslationY: CGFloat, currentTranslationY: CGFloat) {
        isDragging = false
        let maxScroll = max(0, contentHeight)
        
        // Fluid momentum glide based on finger release velocity
        let flickDelta = predictedEndTranslationY - currentTranslationY
        let dampedFlick = -flickDelta * 0.35
        
        var targetOffset = currentOffset + dampedFlick
        targetOffset = max(0, min(targetOffset, maxScroll))
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            self.currentOffset = targetOffset
        }
        
        // If script was actively scrolling before touch, smoothly resume after momentum settles
        if wasScrollingBeforeDrag {
            let workItem = DispatchWorkItem { [weak self] in
                guard let self = self, !self.isDragging else { return }
                self.resumeScrolling()
            }
            resumeWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: workItem)
        }
    }
    
    // Backward compatibility
    func onDragStarted() {
        beginDrag()
    }
    
    func onDragChanged(translationY: CGFloat) {
        updateDrag(translationY: translationY)
    }
    
    private func tick() {
        guard isScrolling && !isDragging else { return }
        let now = Date()
        guard let last = lastUpdateTime else {
            lastUpdateTime = now
            return
        }
        
        let delta = now.timeIntervalSince(last)
        lastUpdateTime = now
        
        let distance = CGFloat(delta * scrollSpeed)
        let maxScroll = max(0, contentHeight)
        
        if scrollDirection == .up {
            if currentOffset + distance >= maxScroll && maxScroll > 0 {
                currentOffset = maxScroll
                pauseScrolling()
            } else {
                currentOffset += distance
            }
        } else {
            if currentOffset - distance <= 0 {
                currentOffset = 0
                pauseScrolling()
            } else {
                currentOffset -= distance
            }
        }
    }
}
