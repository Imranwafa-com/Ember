import Foundation
import AVFoundation
import Combine

// Scans ~/Movies/AnimatedWallpapers for video files, loads their metadata, and generates thumbnails. Watches the directory for changes using GCD file system events with no polling.
final class WallpaperLoader: ObservableObject {

    @Published var wallpapers: [Wallpaper] = []
    @Published var isScanning: Bool = false

    private let thumbnailGenerator = ThumbnailGenerator()
    private let settings = AppSettings.shared
    private var directoryWatcher: DispatchSourceFileSystemObject?
    private var watcherFD: Int32 = -1

    func start() {
        Task { await scan() }
        startWatching()
    }

    func stop() {
        stopWatching()
    }

    @MainActor
    func scan() async {
        isScanning = true
        defer { isScanning = false }

        let dir = settings.wallpaperDirectory
        let fm = FileManager.default

        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)

        guard let contents = try? fm.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        let videoExtensions: Set<String> = ["mp4", "mov", "m4v"]
        let videoFiles = contents.filter { videoExtensions.contains($0.pathExtension.lowercased()) }

        var loaded: [Wallpaper] = []
        for url in videoFiles {
            let asset = AVURLAsset(url: url)
            let duration: TimeInterval
            let resolution: CGSize

            do {
                let d = try await asset.load(.duration)
                duration = d.seconds
            } catch {
                duration = 0
            }

            do {
                let tracks = try await asset.loadTracks(withMediaType: .video)
                if let track = tracks.first {
                    resolution = try await track.load(.naturalSize)
                } else {
                    resolution = .zero
                }
            } catch {
                resolution = .zero
            }

            loaded.append(Wallpaper(url: url, duration: duration, resolution: resolution))
        }

        self.wallpapers = loaded

        for i in loaded.indices {
            let thumb = await thumbnailGenerator.generateThumbnail(for: loaded[i])
            if i < self.wallpapers.count {
                self.wallpapers[i].thumbnailURL = thumb
            }
        }
    }

    private func startWatching() {
        let path = settings.wallpaperDirectory.path
        let fd = open(path, O_EVTONLY)
        guard fd >= 0 else { return }
        watcherFD = fd

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .rename, .delete],
            queue: .main
        )
        source.setEventHandler { [weak self] in
            Task { await self?.scan() }
        }
        source.setCancelHandler {
            close(fd)
        }
        source.resume()
        directoryWatcher = source
    }

    private func stopWatching() {
        directoryWatcher?.cancel()
        directoryWatcher = nil
    }
}
