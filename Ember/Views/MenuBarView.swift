import SwiftUI

// Stack-based navigation container for the menu bar popover, rendering sub-pages inline without sheets. Hosts the main status view, wallpaper grid, preview player, and settings pages.
enum NavigationPage: Equatable {
    case main
    case grid
    case preview(Wallpaper)
    case settings
}

struct MenuBarView: View {
    @EnvironmentObject var engine: WallpaperEngine
    @EnvironmentObject var loader: WallpaperLoader
    @State private var navigationStack: [NavigationPage] = [.main]

    private var currentPage: NavigationPage {
        navigationStack.last ?? .main
    }

    var body: some View {
        Group {
            switch currentPage {
            case .main:
                mainView
            case .grid:
                gridPage
            case .preview(let wallpaper):
                previewPage(wallpaper)
            case .settings:
                settingsPage
            }
        }
        .frame(width: 320)
        .animation(.easeInOut(duration: 0.15), value: navigationStack.count)
    }

    private func push(_ page: NavigationPage) {
        navigationStack.append(page)
    }

    private func pop() {
        guard navigationStack.count > 1 else { return }
        navigationStack.removeLast()
    }

    private var mainView: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text("Ember")
                    .fontWeight(.semibold)
                Spacer()
                statusBadge
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            if let wallpaper = engine.currentWallpaper {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(wallpaper.filename)
                            .font(.caption)
                            .lineLimit(1)
                        Text(engine.isPlaying ? "Playing" : "Paused")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        engine.togglePause()
                    } label: {
                        Image(systemName: engine.userPaused ? "play.fill" : "pause.fill")
                    }
                    .buttonStyle(.borderless)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            } else {
                Text("No wallpaper active")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            }

            Divider()

            VStack(spacing: 2) {
                MenuButton(title: "Choose Wallpaper...", icon: "photo.on.rectangle") {
                    push(.grid)
                }
                MenuButton(title: "Open Wallpaper Folder", icon: "folder") {
                    let url = AppSettings.shared.wallpaperDirectory
                    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
                    NSWorkspace.shared.open(url)
                }
                MenuButton(title: "Settings...", icon: "gear") {
                    push(.settings)
                }

                Divider()
                    .padding(.vertical, 4)

                MenuButton(title: "Quit Ember", icon: "xmark.circle") {
                    engine.tearDown()
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var gridPage: some View {
        VStack(spacing: 0) {
            navigationHeader(title: "Wallpapers")

            Divider()

            WallpaperGrid(onSelect: { wallpaper in
                push(.preview(wallpaper))
            })
            .environmentObject(loader)
            .environmentObject(engine)
        }
    }

    private func previewPage(_ wallpaper: Wallpaper) -> some View {
        VStack(spacing: 0) {
            navigationHeader(title: "Preview")

            Divider()

            PreviewPlayer(wallpaper: wallpaper, onApply: {
                navigationStack = [.main]
            })
            .environmentObject(engine)
        }
    }

    private var settingsPage: some View {
        VStack(spacing: 0) {
            navigationHeader(title: "Settings")

            Divider()

            SettingsView()
                .environmentObject(engine)
        }
    }

    private func navigationHeader(title: String) -> some View {
        HStack(spacing: 6) {
            Button {
                pop()
            } label: {
                HStack(spacing: 2) {
                    Image(systemName: "chevron.left")
                        .font(.caption.weight(.semibold))
                    Text("Back")
                        .font(.callout)
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.accentColor)

            Spacer()

            Text(title)
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            Text("Back")
                .font(.callout)
                .hidden()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(engine.isPlaying ? Color.green : Color.secondary)
                .frame(width: 6, height: 6)
            Text(engine.isPlaying ? "Active" : "Idle")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

private struct MenuButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .frame(width: 16)
                Text(title)
                    .font(.callout)
                Spacer()
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }
}
