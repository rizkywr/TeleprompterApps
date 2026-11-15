import SwiftUI

struct TeleprompterSettingsView: View {
    @ObservedObject var viewModel: TeleprompterViewModel
    @ObservedObject var cameraManager: CameraManager
    @Environment(\.dismiss) private var dismiss
    
    enum SettingsTab: String, CaseIterable, Identifiable {
        case camera = "Camera"
        case prompter = "Prompter"
        
        var id: String { rawValue }
    }
    
    @Binding var selectedTab: SettingsTab
    
    init(viewModel: TeleprompterViewModel, cameraManager: CameraManager, selectedTab: Binding<SettingsTab>) {
        self.viewModel = viewModel
        self.cameraManager = cameraManager
        self._selectedTab = selectedTab
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Native Segmented Tab Selector
                Picker("Settings Category", selection: $selectedTab) {
                    ForEach(SettingsTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color(uiColor: .systemGroupedBackground))
                
                // Single unified Form container guarantees seamless touch events and scrolling
                Form {
                    if selectedTab == .camera {
                        cameraSettingsSections
                    } else {
                        prompterSettingsSections
                    }
                }
            }
            .navigationTitle(selectedTab == .camera ? "Camera Settings" : "Prompter Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                }
            }
        }
    }
    
    // MARK: - Camera Settings Sections
    @ViewBuilder
    private var cameraSettingsSections: some View {
        Section {
            ForEach(VideoResolutionFormat.allCases) { format in
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    cameraManager.applyVideoFormat(format)
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(format.rawValue)
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.primary)
                            
                            Text(format.storageFootnote)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if cameraManager.videoFormat == format {
                            Image(systemName: "checkmark")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(AppTheme.lightBlue)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("Record Video")
                .foregroundColor(.secondary)
        } footer: {
            Text("A minute of video will vary in size based on selected resolution and frame rate. 1080p HD at 60 fps is recommended for smooth, high quality recording.")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        
        Section("Composition & Framing") {
            Toggle(isOn: Binding(
                get: { cameraManager.showGrid },
                set: { cameraManager.setGrid(enabled: $0) }
            )) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Grid (3x3)")
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                    Text("Displays composition rule-of-thirds grid lines")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
            
            Toggle(isOn: Binding(
                get: { cameraManager.mirrorFrontCamera },
                set: { cameraManager.setMirrorFrontCamera(enabled: $0) }
            )) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Mirror Front Camera")
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                    Text("Records video matching your mirror preview")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
        }
        
        Section("Stabilization") {
            Toggle(isOn: Binding(
                get: { cameraManager.isStabilizationEnabled },
                set: { cameraManager.setStabilization(enabled: $0) }
            )) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Enhanced Stabilization")
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                    Text("Uses cinematic video stabilization to minimize camera shake")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
        }
        
        Section("Camera Hardware") {
            HStack {
                Text("Active Lens")
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                Spacer()
                Text(cameraManager.isFrontCamera ? "Front (FaceTime HD)" : "Back (Wide Angle)")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    cameraManager.switchCamera()
                } label: {
                    Image(systemName: "camera.rotate.fill")
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                        .padding(7)
                        .background(Color(uiColor: .tertiarySystemFill))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(.leading, 6)
            }
            
            if cameraManager.hasTorch {
                Toggle("Torch / Fill Light", isOn: Binding(
                    get: { cameraManager.isTorchOn },
                    set: { cameraManager.setTorch(on: $0) }
                ))
            }
        }
    }
    
    // MARK: - Prompter Settings Sections
    @ViewBuilder
    private var prompterSettingsSections: some View {
        Section("Scrolling Speed") {
            HStack {
                Image(systemName: "tortoise.fill")
                    .foregroundColor(.secondary)
                Slider(value: $viewModel.scrollSpeed, in: 10...100, step: 5)
                Image(systemName: "hare.fill")
                    .foregroundColor(.secondary)
            }
            Text("\(Int(viewModel.scrollSpeed)) pts / sec")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        
        Section("Scroll Direction") {
            Picker("Direction", selection: $viewModel.scrollDirection) {
                ForEach(ScrollDirection.allCases) { dir in
                    Text(dir.rawValue).tag(dir)
                }
            }
            .pickerStyle(.segmented)
        }
        
        Section("Font Size") {
            HStack {
                Text("A")
                    .font(.system(size: 14, weight: .bold))
                Slider(value: $viewModel.fontSize, in: 16...60, step: 2)
                Text("A")
                    .font(.system(size: 28, weight: .bold))
            }
            Text("\(Int(viewModel.fontSize)) pt")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        
        Section("Line Spacing (Jarak Antar Kalimat)") {
            HStack {
                Image(systemName: "arrow.up.and.down.text.horizontal")
                    .foregroundColor(.secondary)
                Slider(value: $viewModel.lineSpacing, in: 4...36, step: 1)
                Text("\(Int(viewModel.lineSpacing)) pt")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(width: 44, alignment: .trailing)
            }
            Text("Distance between consecutive sentences/lines for natural reading rhythm.")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        
        Section("Font Color") {
            HStack(spacing: 16) {
                ForEach(PrompterTextColor.allCases) { item in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        viewModel.textColor = item
                    } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(item.color)
                                    .frame(width: 32, height: 32)
                                    .shadow(color: Color.black.opacity(0.18), radius: 2, x: 0, y: 1)
                                
                                if viewModel.textColor == item {
                                    Circle()
                                        .stroke(Color.primary, lineWidth: 2.5)
                                        .frame(width: 38, height: 38)
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(item == .white || item == .yellow ? .black : .white)
                                }
                            }
                            .frame(width: 40, height: 40)
                            
                            Text(item.rawValue)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
        
        Section("Prompter Position") {
            Picker("Position", selection: $viewModel.position) {
                ForEach(TeleprompterPosition.allCases) { pos in
                    Text(pos.rawValue).tag(pos)
                }
            }
            .pickerStyle(.segmented)
            
            Text("Tip: Place near Top for direct eye contact with the camera.")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        
        Section("Reading Area Size") {
            Picker("Area Size", selection: $viewModel.windowSize) {
                ForEach(PrompterWindowSize.allCases) { size in
                    Text(size.rawValue).tag(size)
                }
            }
            .pickerStyle(.segmented)
            
            Text("Spacious gives you expansive reading height with plenty of vertical breathing room.")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        
        Section("Script Vertical Margins (Padding)") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "arrow.up.to.line")
                        .foregroundColor(AppTheme.lightBlue)
                    Text("Top Padding (Jarak Atas)")
                        .font(.system(size: 15))
                    Spacer()
                    Text("\(Int(viewModel.topPadding)) pt")
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                Slider(value: $viewModel.topPadding, in: 20...200, step: 5)
            }
            .padding(.vertical, 2)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "arrow.down.to.line")
                        .foregroundColor(AppTheme.lightBlue)
                    Text("Bottom Padding (Jarak Bawah)")
                        .font(.system(size: 15))
                    Spacer()
                    Text("\(Int(viewModel.bottomPadding)) pt")
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                Slider(value: $viewModel.bottomPadding, in: 50...450, step: 10)
            }
            .padding(.vertical, 2)
            
            // Quick Presets
            HStack(spacing: 8) {
                Button("Tight") {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        viewModel.topPadding = 40
                        viewModel.bottomPadding = 120
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button("Balanced") {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        viewModel.topPadding = 80
                        viewModel.bottomPadding = 220
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button("Extra Spacious") {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        viewModel.topPadding = 130
                        viewModel.bottomPadding = 340
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.top, 4)
        }
        
        Section("Text Alignment") {
            Picker("Alignment", selection: $viewModel.textAlignment) {
                Text("Leading").tag(TextAlignment.leading)
                Text("Center").tag(TextAlignment.center)
                Text("Trailing").tag(TextAlignment.trailing)
            }
            .pickerStyle(.segmented)
        }
        
        Section("Appearance") {
            Toggle("Show Background Box", isOn: $viewModel.showBackground)
            
            if viewModel.showBackground {
                Slider(value: $viewModel.backgroundOpacity, in: 0.1...0.9, step: 0.05) {
                    Text("Background Opacity")
                }
                Text("Background opacity: \(Int(viewModel.backgroundOpacity * 100))%")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            
            Toggle("Mirror Text (Physical Prompter)", isOn: $viewModel.isMirrored)
        }
    }
}
