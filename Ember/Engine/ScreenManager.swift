import AppKit
import AVFoundation

// Manages one WallpaperWindow per connected display, sharing a single AVPlayer across all screens so video is decoded once by the GPU. Responds to display connection and disconnection events to keep windows in sync.
@MainActor
final class ScreenManager {

    private var windows: [String: WallpaperWindow] = [:]
    private weak var player: AVPlayer?

    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func configureWindows(with player: AVPlayer) {
        self.player = player
        syncWindows()
    }

    func tearDown() {
        windows.values.forEach { $0.orderOut(nil) }
        windows.removeAll()
    }

    @objc private func screenParametersChanged(_ notification: Notification) {
        syncWindows()
    }

    private func syncWindows() {
        guard let player = self.player else { return }

        let currentScreens = NSScreen.screens
        let currentIDs = Set(currentScreens.map { screenID(for: $0) })
        let trackedIDs = Set(windows.keys)

        for id in trackedIDs.subtracting(currentIDs) {
            windows[id]?.orderOut(nil)
            windows.removeValue(forKey: id)
        }

        for screen in currentScreens {
            let id = screenID(for: screen)
            if let existing = windows[id] {
                existing.resize(to: screen.frame)
            } else {
                let window = WallpaperWindow(screen: screen, player: player)
                window.orderFrontRegardless()
                windows[id] = window
            }
        }
    }

    private func screenID(for screen: NSScreen) -> String {
        let name = screen.localizedName
        let origin = screen.frame.origin
        return "\(name)_\(Int(origin.x))_\(Int(origin.y))"
    }
}
