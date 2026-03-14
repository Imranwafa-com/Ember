import AppKit
import AVFoundation

// Generates and caches 480x270 JPEG thumbnails for wallpaper videos using AVAssetImageGenerator, storing them in ~/Library/Caches/com.ember.app/Thumbnails. Returns a cached file if one already exists.
final class ThumbnailGenerator {

    private let cacheDir: URL = {
        let cache = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return cache.appendingPathComponent("com.ember.app/Thumbnails", isDirectory: true)
    }()

    init() {
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }

    func generateThumbnail(for wallpaper: Wallpaper) async -> URL? {
        let cacheKey = wallpaper.url.lastPathComponent
            .replacingOccurrences(of: ".", with: "_")
        let thumbURL = cacheDir.appendingPathComponent("\(cacheKey).jpg")

        if FileManager.default.fileExists(atPath: thumbURL.path) {
            return thumbURL
        }

        let asset = AVURLAsset(url: wallpaper.url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 480, height: 270)

        do {
            let time = CMTime(seconds: 1, preferredTimescale: 600)
            let (cgImage, _) = try await generator.image(at: time)
            let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))

            guard let tiff = nsImage.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiff),
                  let jpeg = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.8])
            else { return nil }

            try jpeg.write(to: thumbURL)
            return thumbURL
        } catch {
            return nil
        }
    }
}
