import SwiftUI

struct AppSettingsView: View {
    @AppStorage("default_speed") private var defaultSpeed: Double = 40
    @AppStorage("default_font_size") private var defaultFontSize: Double = 30
    @AppStorage("default_countdown") private var defaultCountdown: Int = 3
    @AppStorage("mirror_teleprompter") private var mirrorTeleprompter: Bool = false
    
    // Native Camera Defaults
    @AppStorage("default_video_format") private var defaultVideoFormat: String = VideoResolutionFormat.hd1080p60.rawValue
    @AppStorage("default_show_grid") private var defaultShowGrid: Bool = false
    @AppStorage("mirror_front_camera") private var mirrorFrontCamera: Bool = true
    @AppStorage("video_stabilization") private var videoStabilization: Bool = true
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Seamless background with smooth ambient glow that diffuses into canvas with ZERO harsh lines
                ZStack(alignment: .topLeading) {
                    AppTheme.canvas.ignoresSafeArea()
                    
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
                }
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Hero Header
                        VStack(alignment: .leading, spacing: 8) {
                            EyebrowBadge(text: "PREFERENCES")
                            
                            // HIG Large Title (34pt, Bold, SF Pro Rounded)
                            Text("Settings")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.textPrimary)
                            
                            // HIG Subheadline (15pt, Regular, SF Pro Rounded)
                            Text("Configure your teleprompter and camera defaults.")
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        
                        // Teleprompter Settings Card
                        settingsSectionCard(title: "Teleprompter Defaults") {
                            VStack(spacing: 16) {
                                HStack {
                                    Text("Default Speed")
                                        .font(.system(size: 16, weight: .regular, design: .rounded))
                                        .foregroundColor(AppTheme.textPrimary)
                                    Spacer()
                                    Text("\(Int(defaultSpeed)) pts/sec")
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundColor(AppTheme.accentDeep)
                                }
                                Slider(value: $defaultSpeed, in: 10...100, step: 5)
                                    .tint(AppTheme.textPrimary)
                                
                                Divider().background(AppTheme.separator)
                                
                                HStack {
                                    Text("Default Font Size")
                                        .font(.system(size: 16, weight: .regular, design: .rounded))
                                        .foregroundColor(AppTheme.textPrimary)
                                    Spacer()
                                    Text("\(Int(defaultFontSize)) pt")
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundColor(AppTheme.accentDeep)
                                }
                                Slider(value: $defaultFontSize, in: 18...44, step: 2)
                                    .tint(AppTheme.textPrimary)
                                
                                Divider().background(AppTheme.separator)
                                
                                Toggle(isOn: $mirrorTeleprompter) {
                                    Text("Mirror Text (Rig Support)")
                                        .font(.system(size: 16, weight: .regular, design: .rounded))
                                }
                                .tint(AppTheme.textPrimary)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Native Camera & Recording Settings Card
                        settingsSectionCard(title: "Camera & Recording") {
                            VStack(spacing: 14) {
                                HStack {
                                    Text("Countdown Timer")
                                        .font(.system(size: 16, weight: .regular, design: .rounded))
                                        .foregroundColor(AppTheme.textPrimary)
                                    Spacer()
                                    Picker("Countdown", selection: $defaultCountdown) {
                                        Text("None").tag(0)
                                        Text("3s").tag(3)
                                        Text("5s").tag(5)
                                    }
                                    .pickerStyle(.segmented)
                                    .frame(width: 160)
                                }
                                
                                Divider().background(AppTheme.separator)
                                
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Video Quality")
                                            .font(.system(size: 16, weight: .regular, design: .rounded))
                                            .foregroundColor(AppTheme.textPrimary)
                                        Text("Format & Framerate")
                                            .font(.caption)
                                            .foregroundColor(AppTheme.textSecondary)
                                    }
                                    Spacer()
                                    Picker("Video Quality", selection: $defaultVideoFormat) {
                                        ForEach(VideoResolutionFormat.allCases) { format in
                                            Text(format.shortTitle).tag(format.rawValue)
                                        }
                                    }
                                    .tint(AppTheme.textPrimary)
                                }
                                
                                Divider().background(AppTheme.separator)
                                
                                Toggle(isOn: $defaultShowGrid) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Composition Grid (3x3)")
                                            .font(.system(size: 16, weight: .regular, design: .rounded))
                                            .foregroundColor(AppTheme.textPrimary)
                                        Text("Rule of thirds framing lines on camera feed")
                                            .font(.caption)
                                            .foregroundColor(AppTheme.textSecondary)
                                    }
                                }
                                .tint(AppTheme.textPrimary)
                                
                                Divider().background(AppTheme.separator)
                                
                                Toggle(isOn: $mirrorFrontCamera) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Mirror Front Camera")
                                            .font(.system(size: 16, weight: .regular, design: .rounded))
                                            .foregroundColor(AppTheme.textPrimary)
                                        Text("Save video matching the mirror preview")
                                            .font(.caption)
                                            .foregroundColor(AppTheme.textSecondary)
                                    }
                                }
                                .tint(AppTheme.textPrimary)
                                
                                Divider().background(AppTheme.separator)
                                
                                Toggle(isOn: $videoStabilization) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Enhanced Stabilization")
                                            .font(.system(size: 16, weight: .regular, design: .rounded))
                                            .foregroundColor(AppTheme.textPrimary)
                                        Text("Cinematic camera shake reduction")
                                            .font(.caption)
                                            .foregroundColor(AppTheme.textSecondary)
                                    }
                                }
                                .tint(AppTheme.textPrimary)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // About Card
                        settingsSectionCard(title: "About PromptCam") {
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Version")
                                        .font(.system(size: 16, weight: .regular, design: .rounded))
                                        .foregroundColor(AppTheme.textPrimary)
                                    Spacer()
                                    Text("1.0.0 (Build 1)")
                                        .font(.system(size: 14, weight: .regular, design: .rounded))
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                                
                                Divider().background(AppTheme.separator)
                                
                                HStack {
                                    Text("Creator")
                                        .font(.system(size: 16, weight: .regular, design: .rounded))
                                        .foregroundColor(AppTheme.textPrimary)
                                    Spacer()
                                    Text("Rizky Wr")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundColor(AppTheme.accent)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 100)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private func settingsSectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // HIG Title 3 (20pt, Semibold, SF Pro Rounded)
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
            
            content()
        }
        .padding(18)
        .background(AppTheme.surface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.separator, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
    }
}
