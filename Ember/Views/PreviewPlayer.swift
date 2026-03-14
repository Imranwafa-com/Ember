import SwiftUI
import AVFoundation
import AVKit

// Inline muted video preview for a selected wallpaper with an Apply button. Cleans up the AVPlayer on disappear to avoid resource leaks.
struct PreviewPlayer: View {
    let wallpaper: Wallpaper
    @EnvironmentObject var engine: WallpaperEngine
    @State private var player: AVPlayer?

    var onApply: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if let player {
                VideoPlayer(player: player)
                    .aspectRatio(16/9, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
            } else {
                Rectangle()
                    .fill(.black)
                    .aspectRatio(16/9, contentMode: .fit)
                    .frame(height: 180)
                    .overlay {
                        ProgressView()
                    }
            }

            VStack(spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(wallpaper.filename)
                            .font(.caption.weight(.medium))
                            .lineLimit(1)
                        Text(infoString)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                Button {
                    engine.apply(wallpaper: wallpaper)
                    onApply()
                } label: {
                    Text("Apply Wallpaper")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
            .padding(12)
        }
        .onAppear {
            let avPlayer = AVPlayer(url: wallpaper.url)
            avPlayer.isMuted = true
            avPlayer.play()
            self.player = avPlayer
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }

    private var infoString: String {
        var parts: [String] = []
        if wallpaper.resolution != .zero {
            parts.append("\(Int(wallpaper.resolution.width))×\(Int(wallpaper.resolution.height))")
        }
        if wallpaper.duration > 0 {
            let seconds = Int(wallpaper.duration)
            parts.append("\(seconds / 60):\(String(format: "%02d", seconds % 60))")
        }
        return parts.isEmpty ? "Video" : parts.joined(separator: " · ")
    }
}
