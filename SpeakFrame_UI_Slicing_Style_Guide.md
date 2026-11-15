# SpeakFrame --- UI Slicing & Visual Design Specification

**Purpose:** Visual implementation guide for translating the supplied
iPhone reference into the SpeakFrame native iOS interface.

**Reference direction:** Minimal editorial iOS design with a warm
orange-to-cream gradient hero, large serif page titles, restrained
sans-serif supporting text, soft white cards, subtle separators, and a
quiet bottom tab bar.

> Treat the supplied screenshot as a visual-style reference, not as a
> screen to copy literally. Adapt its visual language to a camera +
> teleprompter product.

------------------------------------------------------------------------

## 1. Design intent

SpeakFrame should feel like a calm, premium creator tool rather than a
crowded camera utility.

### Visual principles

-   **Editorial:** Large serif headings create a distinctive,
    magazine-like identity.
-   **Warm:** Orange, peach, cream, and soft neutral surfaces make the
    app feel approachable.
-   **Minimal:** Keep each screen focused on one primary task.
-   **Quiet hierarchy:** Use strong typography and spacing instead of
    heavy borders or many colors.
-   **Functional camera UI:** The recording studio can become darker and
    more contrast-heavy when the camera is active, while the rest of the
    app retains the warm editorial style.

## 2. Reference screenshot breakdown

The supplied reference has these identifiable visual characteristics:

1.  A large, soft orange / peach / cream gradient occupying the upper
    portion of the screen.
2.  A small rounded-square back control positioned over the gradient.
3.  A pale warm-gray content surface below the hero.
4.  A small peach label with orange text.
5.  A large black serif heading.
6.  Supporting text in a neutral sans-serif font with relaxed line
    spacing.
7.  A white rounded progress card with a strong percentage value and a
    thin orange progress indicator.
8.  A bottom tab bar with four evenly spaced icon-and-label items.
9.  Subtle separators, very limited shadows, and generous whitespace.
10. A white / near-white overall canvas with black primary text and
    muted gray secondary text.

## 3. SpeakFrame design system

Use these as starting tokens. Tune them in the actual iPhone simulator
after implementing the first screen.

### Color tokens

  Token                Hex         Usage
  -------------------- ----------- ----------------------------------------
  `canvas`             `#F7F6F4`   Main app background
  `surface`            `#FFFFFF`   Cards and sheets
  `surfaceSecondary`   `#F0EEEB`   Secondary panels
  `textPrimary`        `#151515`   Main text
  `textSecondary`      `#66625F`   Descriptions and metadata
  `textTertiary`       `#A6A29E`   Disabled labels
  `accent`             `#E96A3A`   Primary accent, progress, active state
  `accentSoft`         `#F8E5DC`   Badges and subtle accent surfaces
  `accentDeep`         `#A9472B`   Pressed states / dark accent
  `separator`          `#E6E3E0`   Dividers and tab-bar border
  `recording`          `#E53935`   Recording indicator only

### Hero gradient

Create a soft, blurred-feeling gradient with warm orange in the
upper-left area fading into peach and cream.

Suggested stops: - `#F36B3F` - `#F7A18A` - `#F8D8CB` - `#F7F6F4`

The hero should not look like a sharp linear stripe. Use a large radial
gradient or layered radial gradients with low contrast and generous
blending. Avoid a saturated neon orange.

### Typography

Use native system typography for most UI, with a serif display face for
editorial page titles.

  -----------------------------------------------------------------------
  Role                    Suggested style         Usage
  ----------------------- ----------------------- -----------------------
  Display title           New York / `.serif`,    Page titles such as
                          34--40 pt, bold         "Your Scripts"

  Section title           SF Pro, 19--22 pt,      Card and section
                          semibold                headings

  Body                    SF Pro, 15--17 pt,      Descriptions and script
                          regular                 previews

  Caption                 SF Pro, 12--13 pt,      Metadata and helper
                          regular                 labels

  Badge                   SF Pro, 11--12 pt,      Small category/status
                          semibold                labels

  Large metric            SF Pro, 30--34 pt, bold Duration, count, or
                                                  progress
  -----------------------------------------------------------------------

Implementation guidance: - Prefer SwiftUI semantic text styles where
possible. - Use `.fontDesign(.serif)` for display headings if the chosen
system font supports the intended look. - Do not use serif typography
for dense controls, buttons, or long paragraphs. - Support Dynamic Type
and avoid fixed-height text containers that clip larger text.

### Spacing and layout

Use an 8-point spacing rhythm.

  Token                      Value
  -------------------- -----------
  `spaceXS`                   4 pt
  `spaceS`                    8 pt
  `spaceM`                   12 pt
  `spaceL`                   16 pt
  `spaceXL`                  24 pt
  `space2XL`                 32 pt
  `space3XL`                 40 pt
  `screenHorizontal`         24 pt
  `cardPadding`          18--20 pt

### Corner radius and elevation

  Element                    Radius
  --------------------- -----------
  Small badge               6--8 pt
  Icon button             10--12 pt
  Standard card           12--16 pt
  Large panel / sheet     20--24 pt
  Pill control              Capsule

Use very subtle shadows only when needed to separate a card from the
canvas. Prefer surface contrast and spacing over strong elevation.

------------------------------------------------------------------------

## 4. App navigation

Use a four-item bottom tab bar, matching the reference's quiet
navigation pattern.

Recommended tabs:

1.  **Scripts** --- saved scripts and create-new entry point.
2.  **Record** --- camera recording studio.
3.  **Takes** --- previous recordings.
4.  **Settings** --- app and recording preferences.

The selected tab uses dark text and a dark icon. Unselected tabs use
muted gray. Use SF Symbols and short labels.

Suggested SF Symbols: - Scripts: `doc.text` - Record: `record.circle` or
`video` - Takes: `play.rectangle` - Settings: `gearshape`

Do not force the bottom tab bar over the active camera preview if it
obstructs recording controls. The Recording Studio may use a dedicated
full-screen presentation with a clear close/back action.

## 5. Screen specifications

### 5.1 Scripts --- home screen

**Goal:** Help users create or find a script quickly.

Visual structure: - Warm gradient hero at the top. - Small greeting or
eyebrow label. - Large serif title: **Your Scripts**. - Short supporting
line: "Prepare your words before you hit record." - Primary orange
action: **New Script**. - White script cards below. - Bottom tab bar.

Script card content: - Script title. - Short preview of the first one or
two lines. - Last edited date. - Optional estimated reading time. -
Small trailing overflow menu for rename, duplicate, and delete.

Empty state: - A simple document icon. - Heading: "No scripts yet". -
Supporting copy: "Write your first script and get ready to record." -
Primary action: "Create Script".

### 5.2 Script Editor

**Goal:** Make writing and editing comfortable.

Visual structure: - Back control. - Small label: `SCRIPT EDITOR`. -
Large serif title or editable title field. - Multiline text editor on a
clean surface. - Word count and estimated reading time below the
editor. - Sticky bottom action: **Continue to Record**.

Behavior: - Keep text editing visually calm and distraction-free. -
Preserve line breaks. - Show a clear keyboard dismissal action if
needed. - Do not let the bottom action cover the text editor or
keyboard. - Save changes reliably.

### 5.3 Recording Studio

**Goal:** Put the user's face, script, and recording controls first.

This screen is intentionally different from the light editorial screens.

Visual direction: - Use a near-black or deep charcoal background around
the camera preview and controls. - Camera preview occupies most of the
available screen. - Teleprompter text appears in a readable translucent
panel over the preview. - Use white text with strong contrast. - Keep
the orange accent for the active recording state, speed control, and
selected settings. - Keep controls large and easy to reach.

Suggested layout: 1. Top row: close/back, camera switch, settings. 2.
Main area: live camera preview. 3. Teleprompter overlay: scrolling
script with adjustable font size and panel opacity. 4. Reading controls:
speed decrement, current speed, speed increment. 5. Bottom controls:
scroll pause/resume and a prominent record/stop control. 6. Recording
timer and small red recording indicator.

Important behavior: - The script overlay is UI only. It must not be
burned into the recorded video in the MVP. - Scrolling speed must be
adjustable before and during recording. - Pause/resume teleprompter
scrolling independently from video recording. - Keep the user's face
clear; allow the overlay panel to be repositioned or collapsed. - Use a
countdown before recording begins. - Avoid placing text directly over
the Dynamic Island or camera cutout.

### 5.4 Takes --- recording library

**Goal:** Find and review previous recordings.

Visual structure: - Warm gradient hero. - Large serif title: **Your
Takes**. - Supporting text: "Review your latest recordings." - White
cards or a clean list with video thumbnails. - Show recording date and
duration. - Tapping a take opens the video review screen.

Empty state: - Heading: "No recordings yet". - Supporting copy: "Your
finished takes will appear here." - Action: "Start Recording".

### 5.5 Video Review

**Goal:** Decide whether to keep or retake a recording.

Visual structure: - Large video preview. - Minimal playback controls. -
Recording name, date, and duration. - Secondary action: **Retake**. -
Destructive action: **Discard**. - Primary action: **Save to Photos**.

Keep the screen visually simple. The user should not mistake Retake,
Discard, and Save as equivalent actions.

### 5.6 Settings

**Goal:** Keep preferences discoverable without cluttering the recording
screen.

Suggested groups: - **Teleprompter:** default speed, text size, text
alignment, panel opacity, default position. - **Recording:** default
camera, resolution, frame rate, countdown. - **Appearance:** system /
light / dark (optional). - **About:** version, privacy policy, support.

Only expose settings that are implemented and tested.

------------------------------------------------------------------------

## 6. Reusable SwiftUI components

Build reusable components before duplicating styling across screens.

Suggested component inventory:

-   `WarmGradientHeader`
-   `EditorialPageTitle`
-   `EyebrowBadge`
-   `PrimaryActionButton`
-   `SecondaryActionButton`
-   `ScriptCard`
-   `TakeCard`
-   `ProgressOrStatusCard`
-   `BottomTabBar`
-   `IconBackButton`
-   `TeleprompterOverlay`
-   `RecordingControlButton`
-   `SpeedControl`
-   `EmptyStateView`

Each component should accept content and state through explicit
properties rather than hard-coding screen-specific data.

## 7. Suggested SwiftUI project structure

``` text
SpeakFrame/
├── App/
│   └── SpeakFrameApp.swift
├── DesignSystem/
│   ├── Colors.swift
│   ├── Typography.swift
│   ├── Spacing.swift
│   ├── Radii.swift
│   └── Components/
│       ├── WarmGradientHeader.swift
│       ├── EditorialPageTitle.swift
│       ├── EyebrowBadge.swift
│       ├── PrimaryActionButton.swift
│       ├── ScriptCard.swift
│       ├── TakeCard.swift
│       └── BottomTabBar.swift
├── Features/
│   ├── Scripts/
│   ├── ScriptEditor/
│   ├── Recording/
│   ├── Takes/
│   ├── VideoReview/
│   └── Settings/
├── Models/
├── Services/
└── Resources/
```

## 8. UI slicing order

Implement and validate the design in this order:

### Slice 1 --- Design foundation

-   Add color, typography, spacing, and radius tokens.
-   Build the gradient header.
-   Build badge, button, card, and tab-bar components.
-   Confirm the visual style on a real iPhone-sized simulator.

### Slice 2 --- Scripts home

-   Build the Scripts tab.
-   Add realistic sample script data.
-   Implement empty and populated states.
-   Check scrolling and safe-area behavior.

### Slice 3 --- Script editor

-   Build title and body editing.
-   Add word count and estimated duration.
-   Implement save and continue actions.
-   Test keyboard layout and long text.

### Slice 4 --- Takes and Settings

-   Build list and empty states.
-   Reuse the same design tokens and card patterns.
-   Avoid introducing new colors or typography without a reason.

### Slice 5 --- Recording Studio

-   Build the dark camera studio separately from the light editorial
    shell.
-   Add camera preview.
-   Add teleprompter overlay and controls.
-   Verify that the overlay is not part of the captured video.

### Slice 6 --- Video Review

-   Build playback, retake, discard, and save actions.
-   Match the visual language while prioritizing clear action hierarchy.

------------------------------------------------------------------------

## 9. Responsive and accessibility requirements

-   Use `safeAreaInsets` and safe-area-aware layout.
-   Test on compact and large iPhone sizes.
-   Avoid hard-coded screen heights.
-   Use scroll views for content that can exceed the viewport.
-   Support Dynamic Type.
-   Use accessibility labels for icon-only controls.
-   Ensure text contrast remains readable over the gradient and camera
    preview.
-   Provide haptic feedback only for meaningful actions, such as
    starting/stopping recording.
-   Respect Reduce Motion where practical.
-   Keep touch targets comfortably large (ideally around 44 × 44 pt or
    larger).

## 10. UI acceptance criteria

The UI implementation is ready for functional integration when:

-   The Scripts home screen clearly matches the warm editorial visual
    direction.
-   Page titles use a distinctive serif style while body text remains
    clean and readable.
-   Gradient, badges, cards, and buttons use shared design tokens.
-   The bottom navigation is consistent across the main app sections.
-   Empty and populated states are designed.
-   The Script Editor supports long multiline content without clipping.
-   The Recording Studio is visually distinct and optimized for
    recording.
-   The teleprompter text remains legible over the camera preview.
-   The teleprompter overlay does not appear in the exported video.
-   Layouts work on more than one iPhone screen size.

------------------------------------------------------------------------

## 11. Prompt for Xcode coding assistant

Use this prompt when implementing the UI in Xcode:

> Implement the SpeakFrame UI in SwiftUI using the attached visual
> reference and this UI slicing specification.
>
> Follow a warm, minimal editorial iOS style: soft orange/peach/cream
> radial gradient headers, near-white backgrounds, large black serif
> page titles, clean SF Pro body typography, subtle white rounded cards,
> restrained orange accents, generous whitespace, and a quiet four-item
> bottom tab bar.
>
> Do not copy the reference screen's project-planning content. Adapt the
> visual style to a teleprompter camera app.
>
> Build the reusable design system first: colors, typography, spacing,
> corner radii, gradient header, badges, buttons, cards, and bottom tab
> bar. Then implement the Scripts home, Script Editor, Takes, and
> Settings screens using sample data.
>
> The Recording Studio should use a separate dark, high-contrast
> recording interface with a live camera preview, a readable scrolling
> teleprompter overlay, speed controls, pause/resume, camera switch,
> timer, and record/stop controls.
>
> Keep the teleprompter overlay as a SwiftUI overlay only; do not burn
> it into the video. Keep views modular, use reusable components,
> respect safe areas and Dynamic Type, and make sure the project
> compiles after each implementation slice.
>
> Before adding camera functionality, complete the static UI with
> realistic sample data and validate all screen layouts in the iPhone
> simulator.
