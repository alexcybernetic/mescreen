# MeScreen

A minimal macOS menu bar app that displays your camera feed in a draggable, always-on-top circular overlay.

![macOS](https://img.shields.io/badge/macOS-14.0+-blue) ![Swift](https://img.shields.io/badge/Swift-5.9+-orange)

## Features

- **Circular camera overlay** — a floating, borderless window with a live camera feed clipped to a circle
- **Always on top** — stays visible across all Spaces and on top of all windows
- **Draggable** — click and drag the circle anywhere on screen
- **Resizable** — choose between Small (100px), Medium (150px), and Large (200px) from the menu bar
- **Smooth transitions** — stream fades out during resize, window animates, stream fades back in
- **Multiple cameras** — switch between built-in and external cameras
- **Menu bar control** — all settings accessible from the status bar icon
- **Accessory app** — no Dock icon, lives entirely in the menu bar

## Requirements

- macOS 14.0+
- Camera access permission

## How It Works

MeScreen runs as a menu bar accessory app (no Dock icon). It creates a borderless, transparent floating window that displays your camera feed inside a circular clip with a white border. The window floats above everything and can be dragged anywhere.

### Architecture

| File | Purpose |
|------|---------|
| `MeScreenApp.swift` | App entry point, window configuration, animated window resizing |
| `CameraManager.swift` | Camera session management, size state, transition orchestration |
| `CameraPreviewView.swift` | `NSViewRepresentable` bridge for `AVCaptureVideoPreviewLayer` |
| `ContentView.swift` | SwiftUI view with circular clip, border, and fade transitions |
| `StatusBarController.swift` | Menu bar icon and dropdown menu for size/camera selection |

## Usage

1. Launch the app — a circular camera overlay appears in the top-right corner
2. **Drag** the circle to reposition it
3. Click the **camera icon** in the menu bar to:
   - Change the overlay size (Small / Medium / Large)
   - Switch between available cameras
   - Quit the app
4. **⌘Q** to quit

## Building

Open `MeScreen.xcodeproj` in Xcode and build for macOS. The app requires camera access — grant permission when prompted, or enable it in **System Settings → Privacy & Security → Camera**.

## License

MIT
# mescreen
