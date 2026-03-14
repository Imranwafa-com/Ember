import AppKit
import Combine

// AppKit lifecycle bridge that owns all long-lived services and wires them together on app launch. Exposes services as ObservableObject instances for the SwiftUI layer.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {

    let wallpaperEngine = WallpaperEngine()
    let wallpaperLoader = WallpaperLoader()
    let powerMonitor = PowerMonitor()
    let activityMonitor = ActivityMonitor()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        wallpaperEngine.powerMonitor = powerMonitor
        wallpaperEngine.activityMonitor = activityMonitor

        powerMonitor.startMonitoring()
        activityMonitor.startMonitoring()

        wallpaperLoader.start()

        restorePreviousWallpaper()
    }

    func applicationWillTerminate(_ notification: Notification) {
        wallpaperEngine.tearDown()
        powerMonitor.stopMonitoring()
        activityMonitor.stopMonitoring()
        wallpaperLoader.stop()
    }

    private func restorePreviousWallpaper() {
        let savedPath = AppSettings.shared.selectedWallpaperURL
        guard !savedPath.isEmpty else { return }

        let url = URL(fileURLWithPath: savedPath)
        guard FileManager.default.fileExists(atPath: url.path) else { return }

        let wallpaper = Wallpaper(url: url)
        wallpaperEngine.apply(wallpaper: wallpaper)
    }
}
