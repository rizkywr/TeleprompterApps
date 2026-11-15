# SpeakFrame --- Native iOS Teleprompter Camera

> Product brief and implementation guide for building a native iOS
> camera app with an on-screen scrolling teleprompter in Xcode.

## 1. Product overview

**Working name:** SpeakFrame\
**Platform:** iOS\
**Development approach:** Native iOS using Swift, SwiftUI, and
AVFoundation\
**Core promise:** Write a script, record yourself while reading it from
the screen, and save a clean video to Photos.

SpeakFrame is designed for creators who record talking-head videos,
tutorials, product reviews, presentations, and social content. The
teleprompter text is visible on the device screen while recording, but
**is not burned into the exported video** in the initial MVP.

## 2. MVP decisions

Use these defaults unless product testing suggests otherwise:

-   **Teleprompter mode:** Floating on-screen overlay; exported video
    remains clean.
-   **Camera support:** Front and rear cameras.
-   **Scrolling control:** Manual speed control with pause/resume.
-   **Script input:** Type, paste, edit, and save scripts.
-   **Recording:** Video with microphone audio.
-   **Export:** Save the recorded video to the iOS Photos library.
-   **Initial scope:** No video editor, filters, cloud sync, AI script
    generation, or voice-following scroll in MVP.

## 3. Core user flow

1.  Open the app.
2.  Create a new script or choose a saved script.
3.  Enter a title and script body, or paste text.
4.  Open the recording studio.
5.  Grant camera, microphone, and Photos permissions when requested.
6.  Choose front or rear camera.
7.  Adjust text size, scroll speed, and text position.
8.  Start a short countdown.
9.  Record while the script scrolls over the live camera preview.
10. Pause/resume recording or teleprompter scrolling as needed.
11. Stop recording.
12. Preview the result.
13. Retake, discard, or save to Photos.

## 4. Main screens

### 4.1 Home / Script Library

Purpose: Give users a clear starting point and access to saved scripts.

Elements: - App title and concise description. - Primary action: **New
Script**. - List of saved scripts. - Script title, last edited date, and
optional estimated reading duration. - Open, edit, duplicate, and delete
actions. - Empty state that explains how to create the first script.

### 4.2 Script Editor

Purpose: Prepare the words before recording.

Elements: - Script title field. - Multiline script editor. -
Paste-friendly text input. - Character and word count. - Estimated
reading duration (optional; use an adjustable assumed words-per-minute
value). - Save action. - Continue to recording action.

Behavior: - Preserve line breaks and paragraph spacing. - Autosave or
save explicitly; avoid losing text when navigating away. - Handle long
scripts without freezing the UI. - Do not require an account.

### 4.3 Recording Studio

Purpose: Record video while reading the scrolling script.

Layout: - Live camera preview as the main background. - Teleprompter
text overlay placed near the camera area. - Clear recording indicator
and elapsed time. - Large record/stop control. - Front/rear camera
switch. - Settings access for text and recording preferences. - Scroll
speed control. - Pause/resume scrolling control.

Teleprompter behavior: - Scroll text vertically at a user-controlled
speed. - Provide a visible start position and enough space above/below
the reading line. - Keep text readable over bright or busy camera
backgrounds using a subtle translucent backing or text shadow. - Allow
text size adjustment. - Allow the user to reposition the text area (at
minimum: top, center, bottom; drag-to-position can be a later
enhancement). - Support mirrored text as an optional setting only if a
physical teleprompter mirror workflow is supported; normal on-screen use
should default to readable, non-mirrored text. - Scrolling should be
smooth and driven by elapsed time rather than a fixed number of points
per frame. - Pause scrolling independently from recording when needed. -
When recording starts, offer a short countdown before scrolling
begins. - Reset scroll position when the user chooses Retake or Restart
Script.

Important distinction: - The teleprompter overlay is a SwiftUI interface
layered over the camera preview. - It should **not** be composited into
the recorded video in the MVP. - The exported recording should contain
only the camera video and microphone audio.

### 4.4 Video Review

Purpose: Let the user check the take before saving.

Elements: - Video playback preview. - Retake action. - Delete/discard
action. - Save to Photos action. - Clear saving progress and
success/error feedback.

Behavior: - Keep the temporary recording until the user saves or
discards it. - Request Photos permission only when needed. - Handle
permission denial with a clear route to iOS Settings. - Do not claim a
save succeeded until the Photos save operation completes.

## 5. Functional requirements

### Script management

-   Create, read, update, and delete scripts.
-   Store scripts locally on device.
-   Support multiline text and pasted content.
-   Persist changes between app launches.
-   Sort scripts by most recently edited.

### Camera and recording

-   Use AVFoundation for native capture.
-   Support front and rear camera where available.
-   Capture video and microphone audio.
-   Show a live camera preview.
-   Start, pause, resume, and stop recording where supported by the
    chosen capture pipeline.
-   Display recording duration.
-   Handle camera/microphone permission states.
-   Handle interruptions, app backgrounding, and capture-session errors
    gracefully.
-   Save output in a widely compatible format, preferably .mov or .mp4
    based on the selected export pipeline.

### Teleprompter

-   Adjustable scrolling speed.
-   Adjustable font size.
-   Pause/resume scrolling.
-   Restart from the beginning.
-   Adjustable text panel position.
-   Readable contrast over the camera preview.
-   Smooth scrolling that remains stable during recording.

### Video library

-   Preview the most recent take.
-   Retake or discard.
-   Save to Photos.
-   Provide clear errors if saving fails.

## 6. Suggested technical architecture

Keep camera capture logic separate from SwiftUI views.

``` text
SpeakFrame/
├── App/
│   ├── SpeakFrameApp.swift
│   └── AppCoordinator.swift
├── Features/
│   ├── Home/
│   │   ├── HomeView.swift
│   │   └── ScriptListView.swift
│   ├── ScriptEditor/
│   │   ├── ScriptEditorView.swift
│   │   └── ScriptEditorViewModel.swift
│   ├── Camera/
│   │   ├── CameraStudioView.swift
│   │   ├── CameraPreviewView.swift
│   │   ├── CameraViewModel.swift
│   │   └── CameraManager.swift
│   ├── Teleprompter/
│   │   ├── TeleprompterView.swift
│   │   ├── TeleprompterSettingsView.swift
│   │   └── TeleprompterViewModel.swift
│   └── VideoReview/
│       ├── VideoReviewView.swift
│       └── PhotosExporter.swift
├── Models/
│   ├── Script.swift
│   └── Recording.swift
├── Services/
│   ├── PermissionsManager.swift
│   └── ScriptStore.swift
└── Resources/
    └── Assets.xcassets
```

### Recommended responsibilities

-   **SwiftUI:** Navigation, script editor, recording controls,
    teleprompter overlay, review UI.
-   **AVFoundation:** Camera discovery, capture session, video/audio
    input, recording output, session lifecycle.
-   **AVCaptureVideoPreviewLayer:** Display the live camera feed inside
    SwiftUI through a `UIViewRepresentable`, or use an equivalent
    supported preview approach.
-   **AVCaptureMovieFileOutput:** A practical first implementation for
    recording video with audio.
-   **Photos framework:** Save the finished recording to the user's
    Photos library.
-   **SwiftData or Codable + file storage:** Persist scripts locally.
    Choose one approach for MVP; avoid unnecessary infrastructure.

## 7. Important implementation notes

### Camera session lifecycle

-   Configure and start the capture session off the main thread.
-   Keep capture-session work on a dedicated serial queue.
-   Update SwiftUI state on the main actor.
-   Do not repeatedly rebuild the capture session when changing
    unrelated UI settings.
-   Reconfigure inputs safely when switching front/rear cameras.
-   Handle unavailable cameras and unsupported formats.

### Permissions

Add the relevant usage descriptions to `Info.plist`:

-   `NSCameraUsageDescription` --- explain that camera access is needed
    to record videos.
-   `NSMicrophoneUsageDescription` --- explain that microphone access is
    needed to record audio.
-   `NSPhotoLibraryAddUsageDescription` --- explain that access is
    needed to save recordings to Photos, if required by the selected
    Photos API and deployment target.

Request access at the point where the user first invokes the relevant
feature, not immediately on app launch.

### Teleprompter scrolling

-   Use a time-based animation or a display-link-driven scrolling
    implementation.
-   Make speed a user-facing value with a sensible default and a broad
    but usable range.
-   Ensure pause/resume does not jump the text unexpectedly.
-   Avoid tying scrolling to the camera preview's frame rate.
-   Test with short and long scripts, different Dynamic Type sizes, and
    device rotation if rotation is supported.

### Audio and interruptions

-   Configure `AVAudioSession` deliberately for video recording with
    microphone input.
-   Test incoming calls, audio route changes, microphone permission
    denial, and app interruptions.
-   Make the app's behavior clear if recording is interrupted.

### Orientation and safe areas

-   Decide whether the MVP supports portrait only or portrait and
    landscape.
-   Keep recording controls reachable and avoid covering the user's face
    with the teleprompter.
-   Respect safe areas and camera cutouts.

## 8. Suggested MVP settings

  Setting              Initial default
  -------------------- -------------------------------
  Camera               Front
  Recording quality    1080p
  Frame rate           30 fps
  Teleprompter speed   Medium
  Text size            Medium / large
  Text alignment       Center
  Text panel           Subtle translucent background
  Countdown            3 seconds
  Mirror text          Off
  Export overlay       Off

Camera formats and frame rates must be selected from formats actually
supported by the active device. Do not hard-code a 4K/60 fps promise for
every device.

## 9. Visual direction

Design principles: - Native-feeling iOS interface. - Minimal controls
during recording. - Strong visual hierarchy: script is readable,
record/stop is obvious, secondary settings stay out of the way. - Dark
recording studio UI to reduce glare and distraction. - Light or system
appearance for script management, unless a consistent dark theme is
preferred. - Use SF Symbols where appropriate. - Support accessibility
labels, Dynamic Type, and sufficient contrast.

Avoid: - Crowded camera controls. - Tiny scrolling text. - Settings that
cover the camera preview. - Decorative animations that distract while
recording.

## 10. Non-goals for the first MVP

Do not build these until the core recording flow works reliably: - AI
script writing. - Voice-following / speech-recognition-based
scrolling. - Automatic captions or subtitles. - Burned-in text export. -
Video trimming and editing. - LUTs, filters, and color grading. - Cloud
accounts and script synchronization. - Social media publishing. -
Multi-camera recording.

## 11. Development milestones

### Milestone 1 --- App foundation

-   Create the Xcode project using SwiftUI.
-   Build navigation and the script library.
-   Implement local script persistence.
-   Build the script editor.

**Acceptance criteria:** A user can create, edit, save, reopen, and
delete scripts.

### Milestone 2 --- Camera preview

-   Request camera permission.
-   Configure AVFoundation capture session.
-   Display live front-camera preview.
-   Add front/rear camera switching.
-   Request microphone permission.

**Acceptance criteria:** Live preview works reliably and camera
switching does not crash or freeze the UI.

### Milestone 3 --- Recording

-   Add video and audio recording.
-   Add recording timer and stop control.
-   Handle errors and interruptions.
-   Store the temporary recording URL.

**Acceptance criteria:** A user can record a video with sound and play
it back.

### Milestone 4 --- Teleprompter

-   Overlay script text over the live preview.
-   Implement smooth scrolling.
-   Add speed and font-size controls.
-   Add pause, resume, and restart.
-   Add countdown.

**Acceptance criteria:** Text scrolls smoothly while recording, and the
exported video does not contain the teleprompter overlay.

### Milestone 5 --- Review and export

-   Build video playback review.
-   Add retake and discard.
-   Save to Photos.
-   Add permission and failure states.

**Acceptance criteria:** A user can review a take and save it
successfully to Photos.

### Milestone 6 --- Device testing and polish

-   Test on physical iPhones.
-   Test front and rear cameras.
-   Test long recordings and long scripts.
-   Test permission denial and interruptions.
-   Test memory use, thermal behavior, and recording stability.
-   Refine accessibility and layout.

## 12. Definition of done

The MVP is ready for user testing when a person can:

1.  Create and save a script.
2.  Open the recording studio.
3.  See a live camera preview.
4.  Read the script while it scrolls over the preview.
5.  Adjust scrolling speed and text size.
6.  Pause and resume scrolling.
7.  Record video with microphone audio.
8.  Stop and preview the recording.
9.  Retake or discard the recording.
10. Save a clean video to Photos, with no teleprompter text burned into
    it.

## 13. Suggested first Xcode build prompt

Build the project incrementally. Start with the app foundation and
script library, then implement camera capture as a separate feature. Do
not attempt to generate the entire app in one pass.

**First task:** Create a SwiftUI iOS app named SpeakFrame with: - A home
screen showing a list of saved scripts. - A prominent New Script
button. - A script editor with title and multiline body fields. - Local
persistence for scripts. - Navigation from a saved script into a
placeholder Recording Studio screen. - A clean, modern native iOS
design.

Use clear separation between Views, ViewModels, Models, and Services.
Make the project compile before adding AVFoundation camera
functionality.
