import SwiftUI
import ServiceManagement

// Settings panel embedded inline in the menu bar popover, providing controls for playback speed, boomerang mode, frame rate cap, power management, idle timeout, and launch-at-login.
struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @EnvironmentObject var engine: WallpaperEngine

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                settingsSection("Playback") {
                    HStack {
                        Text("Speed")
                        Spacer()
                        Picker("", selection: Binding(
                            get: { settings.playbackSpeed },
                            set: { engine.updateSpeed($0) }
                        )) {
                            ForEach(AppSettings.speedOptions, id: \.value) { option in
                                Text(option.label).tag(option.value)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 120)
                    }

                    Toggle("Boomerang mode", isOn: Binding(
                        get: { settings.boomerangMode },
                        set: { engine.toggleBoomerang($0) }
                    ))
                    .help("Play forward then reverse in a loop")

                    Toggle("Limit frame rate (30 fps)", isOn: Binding(
                        get: { settings.limitFrameRate },
                        set: { settings.limitFrameRate = $0 }
                    ))
                    .help("Reduce GPU usage by capping playback to 30 fps")
                }

                Divider()

                settingsSection("Power") {
                    Toggle("Pause on battery power", isOn: Binding(
                        get: { settings.pauseOnBattery },
                        set: { settings.pauseOnBattery = $0 }
                    ))
                    .help("Automatically pause when running on battery")
                }

                Divider()

                settingsSection("Idle") {
                    HStack {
                        Text("Auto-pause after idle")
                        Spacer()
                        Picker("", selection: Binding(
                            get: { settings.pauseAfterIdleMinutes },
                            set: { settings.pauseAfterIdleMinutes = $0 }
                        )) {
                            ForEach(AppSettings.idleOptions, id: \.value) { option in
                                Text(option.label).tag(option.value)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 120)
                    }
                    .help("Pause playback when the Mac has been idle")
                }

                Divider()

                settingsSection("System") {
                    Toggle("Launch at login", isOn: Binding(
                        get: { settings.launchAtLogin },
                        set: { newValue in
                            settings.launchAtLogin = newValue
                            updateLoginItem(enabled: newValue)
                        }
                    ))
                    .help("Start Ember automatically when you log in")
                }

                Divider()

                settingsSection("Wallpaper Folder") {
                    HStack {
                        Text(settings.wallpaperDirectory.path)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                        Button("Open") {
                            let url = settings.wallpaperDirectory
                            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
                            NSWorkspace.shared.open(url)
                        }
                        .controlSize(.small)
                    }
                }

                Divider()

                HStack {
                    Text("Ember")
                        .fontWeight(.medium)
                    Text("v1.0")
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            }
            .padding(12)
        }
        .toggleStyle(.switch)
    }

    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            content()
                .font(.callout)
        }
    }

    private func updateLoginItem(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            settings.launchAtLogin = !enabled
        }
    }
}
