# Memory Box

A native iOS app for collecting, viewing, and reliving personal memories through photos, dates, and short notes.

## Requirements

- Xcode 15+
- iOS 17.0+
- Swift 5.9+

## Getting Started

1. Open `MemoryBox/MemoryBox.xcodeproj` in Xcode
2. Select your development team under **Signing & Capabilities**
3. Choose an iPhone simulator or device
4. Press **Run** (⌘R)

## Features

### Three Ways to Browse Memories

- **Gravity** — Memory cards fall with UIKit Dynamics physics. Drag them around; they collide with each other and the screen edges.
- **Canvas** — An infinite 3000×3000pt pan/zoom canvas. Long-press a card to drag it; positions persist via SwiftData.
- **Shelf** — Memories grouped by year in a horizontal scrolling shelf layout.

### Add Memories

Tap **+** on any tab to open the add-memory sheet:

- Title (required, 50 chars max)
- Date picker
- Optional note (200 chars max)
- Photo from library (PhotosUI) or camera (AVFoundation)
- **Remove background** (Vision framework, on-device) — cutout saved as PNG to preserve transparency; unprocessed photos saved as JPEG at 0.7 quality

## Architecture

- **MVVM** with SwiftUI shell and UIKit for physics/gesture-heavy views
- **SwiftData** for persistence
- **PhotosUI** / **AVFoundation** for media capture

## Project Structure

```
MemoryBox/
├── MemoryBoxApp.swift
├── Models/
│   └── Memory.swift
├── Views/
│   ├── ContentView.swift
│   ├── GravityView.swift
│   ├── GravityViewController.swift
│   ├── CanvasView.swift
│   ├── CanvasViewController.swift
│   ├── ShelfView.swift
│   ├── AddMemorySheet.swift
│   ├── MemoryCard.swift
│   └── MemoryDetailSheet.swift
└── Utilities/
    ├── DateFormatters.swift
    └── BackgroundRemover.swift
```

## Design

- Accent color: warm amber `#E8A020`
- Light and dark mode supported
- SF Symbols for tab bar icons

## Simulator Notes

The **Take Photo** button is hidden on simulators where no camera is available. Use **Choose Photo** to pick from the photo library instead.

**Background removal** requires a physical device — Vision's foreground instance mask is not available in the Simulator. An alert is shown if removal fails.
