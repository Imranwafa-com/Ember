import Foundation
import SwiftUI

// Persisted app configuration backed by UserDefaults, with manual objectWillChange publishing to ensure Combine observers fire correctly. Provides typed accessors for all user-configurable settings.
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private let defaults = UserDefaults.standard

    var pauseOnBattery: Bool {
        get { defaults.bool(forKey: "pauseOnBattery") }
        set { objectWillChange.send(); defaults.set(newValue, forKey: "pauseOnBattery") }
    }

    var pauseAfterIdleMinutes: Int {
        get { defaults.integer(forKey: "pauseAfterIdleMinutes") }
        set { objectWillChange.send(); defaults.set(newValue, forKey: "pauseAfterIdleMinutes") }
    }

    var limitFrameRate: Bool {
        get { defaults.bool(forKey: "limitFrameRate") }
        set { objectWillChange.send(); defaults.set(newValue, forKey: "limitFrameRate") }
    }

    var playbackSpeed: Float {
        get {
            let val = defaults.float(forKey: "playbackSpeed")
            return val > 0 ? val : 1.0
        }
        set { objectWillChange.send(); defaults.set(newValue, forKey: "playbackSpeed") }
    }

    var boomerangMode: Bool {
        get { defaults.bool(forKey: "boomerangMode") }
        set { objectWillChange.send(); defaults.set(newValue, forKey: "boomerangMode") }
    }

    var launchAtLogin: Bool {
        get { defaults.bool(forKey: "launchAtLogin") }
        set { objectWillChange.send(); defaults.set(newValue, forKey: "launchAtLogin") }
    }

    var selectedWallpaperURL: String {
        get { defaults.string(forKey: "selectedWallpaperURL") ?? "" }
        set { objectWillChange.send(); defaults.set(newValue, forKey: "selectedWallpaperURL") }
    }

    var wallpaperDirectory: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent("Movies/AnimatedWallpapers", isDirectory: true)
    }

    static let speedOptions: [(label: String, value: Float)] = [
        ("0.25×", 0.25),
        ("0.5×", 0.5),
        ("0.75×", 0.75),
        ("1× (Normal)", 1.0),
        ("1.25×", 1.25),
        ("1.5×", 1.5),
        ("2×", 2.0),
    ]

    static let idleOptions: [(label: String, value: Int)] = [
        ("Disabled", 0),
        ("1 minute", 1),
        ("2 minutes", 2),
        ("5 minutes", 5),
        ("10 minutes", 10),
        ("15 minutes", 15),
        ("30 minutes", 30),
    ]

    private init() {
        defaults.register(defaults: [
            "pauseOnBattery": true,
            "launchAtLogin": false,
            "limitFrameRate": false,
            "selectedWallpaperURL": "",
            "playbackSpeed": 1.0,
            "boomerangMode": false,
            "pauseAfterIdleMinutes": 0,
        ])
    }
}
