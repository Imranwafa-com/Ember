import SwiftUI

// Grid view displaying wallpaper thumbnail cards with lazy loading, embedded inline in the menu bar popover. Tapping a card triggers `onSelect` to push the preview page.
struct WallpaperGrid: View {
    @EnvironmentObject var loader: WallpaperLoader
    @EnvironmentObject var engine: WallpaperEngine

    var onSelect: (Wallpaper) -> Void

    private let columns = [GridItem(.adaptive(minimum: 120, maximum: 150), spacing: 8)]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if loader.isScanning {
                    ProgressView()
                        .scaleEffect(0.7)
                }
                Spacer()
                Button {
                    Task { await loader.scan() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .help("Rescan wallpaper folder")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)

            if loader.wallpapers.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(loader.wallpapers) { wallpaper in
                            WallpaperCard(
                                wallpaper: wallpaper,
                                isActive: engine.currentWallpaper?.id == wallpaper.id
                            )
                            .onTapGesture {
                                onSelect(wallpaper)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }
        }
        .frame(minHeight: 280)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "film.stack")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text("No wallpapers found")
                .font(.headline)
            Text("Add .mp4 videos to\n~/Movies/AnimatedWallpapers")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Open Folder") {
                let url = AppSettings.shared.wallpaperDirectory
                try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
                NSWorkspace.shared.open(url)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

struct WallpaperCard: View {
    let wallpaper: Wallpaper
    let isActive: Bool

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Rectangle()
                    .fill(Color.black.opacity(0.2))
                    .aspectRatio(16/9, contentMode: .fit)
                    .cornerRadius(6)

                if let thumbURL = wallpaper.thumbnailURL,
                   let nsImage = NSImage(contentsOf: thumbURL) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 80)
                        .clipped()
                        .cornerRadius(6)
                } else {
                    Image(systemName: "film")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isActive ? Color.accentColor : Color.clear, lineWidth: 2)
            )

            Text(wallpaper.filename)
                .font(.caption2)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .contentShape(Rectangle())
    }
}
