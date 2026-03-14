# Ember

A lightweight, high-performance animated wallpaper engine for macOS. Built with a strict focus on system efficiency — run stunning video wallpapers without draining your battery or hogging resources.

## Overview

Ember uses exclusively hardware-accelerated video playback and smart power-saving features to keep your Mac fast and responsive while displaying animated wallpapers.

## Features

- **Hardware-Accelerated Playback** — `AVPlayer` and `AVPlayerLayer` for seamless `.mp4` video looping
- **True Desktop Integration** — Renders behind Finder icons, spans the full screen, supports multi-monitor setups
- **Smart Power Management** — Automatically pauses playback when:
  - Mac switches to battery power
  - A fullscreen app is detected
  - The screen is locked or the display sleeps
- **Wallpaper Manager** — Scans `~/Movies/AnimatedWallpapers`, generates thumbnails, and caches metadata
- **Minimal UI** — Clean SwiftUI interface for browsing, previewing, and applying wallpapers
- **Low Resource Footprint** — Under ~100MB RAM, shared AVPlayer instances, limited redraws. No WebViews or manual frame rendering.

## Resource Usage

```console
PID     USER        PRI  NI   VIRT    RES     S   CPU%  MEM%   TIME+     COMMAND
56398   imranwafa   17   0    415G    68416   S   0.1   0.2    0:00.24   /Users/imranwafa/Documents/Projects/Ember/build/Ember.app/Contents/MacOS/Ember
```

## Tech Stack

- **Swift**
- **SwiftUI** — UI rendering
- **AppKit** — Window and screen management
- **AVFoundation** — Hardware-accelerated video playback

## Architecture

```
Ember
 ├── Engine/
 │   ├── WallpaperEngine.swift
 │   ├── ScreenManager.swift
 │   └── WallpaperWindow.swift
 ├── Models/
 │   ├── Wallpaper.swift
 │   └── AppSettings.swift
 ├── Services/
 │   ├── WallpaperLoader.swift
 │   ├── ThumbnailGenerator.swift
 │   ├── ActivityMonitor.swift
 │   └── PowerMonitor.swift
 ├── Views/
 │   ├── WallpaperGrid.swift
 │   ├── PreviewPlayer.swift
 │   ├── SettingsView.swift
 │   └── MenuBarView.swift
 └── EmberApp.swift
```

## Requirements

- macOS 13.0 or later
- Xcode 15.0 or later (for building)

## Build

### Xcode

1. Open `Ember.xcodeproj` or `Package.swift` in Xcode.
2. Select your Mac as the run destination.
3. Press `Cmd + R` to build and run.

### Command Line

```bash
xcodebuild -project Ember.xcodeproj -scheme Ember -configuration Release build
```

Or use the provided build script:

```bash
./build.sh
```

## Usage

1. Launch Ember.
2. The app creates a folder at `~/Movies/AnimatedWallpapers` on first run.
3. Drop `.mp4` looping videos into that folder.
4. Use the Ember UI to select and apply a wallpaper.

## Contributing

Contributions are welcome. Feel free to open an issue or submit a pull request.

## License

MIT License — see [LICENSE](LICENSE) for details.
