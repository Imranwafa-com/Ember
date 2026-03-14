import SwiftUI

/// Main entry point for Ember.
///
/// Uses MenuBarExtra (macOS 13+) for a modern menu bar experience.
/// The `.window` style gives us a rich SwiftUI popover instead of a basic NSMenu.
/// LSUIElement=true in Info.plist keeps the app out of the Dock.
@main
struct EmberApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Menu bar icon — the primary way users interact with Ember
        MenuBarExtra("Ember", systemImage: "flame.fill") {
            MenuBarView()
                .environmentObject(appDelegate.wallpaperEngine)
                .environmentObject(appDelegate.wallpaperLoader)
        }
        .menuBarExtraStyle(.window)

        // Settings window opened via Cmd+, or the "Settings..." button
        Settings {
            SettingsView()
                .environmentObject(appDelegate.wallpaperEngine)
        }
    }
}
