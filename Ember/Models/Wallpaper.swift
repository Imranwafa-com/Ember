import Foundation
import CoreGraphics

// Data model representing a single animated wallpaper video file with its metadata.
struct Wallpaper: Identifiable, Hashable {
    let id: UUID
    let url: URL
    let filename: String
    let duration: TimeInterval
    let resolution: CGSize
    var thumbnailURL: URL?
    let dateAdded: Date

    init(url: URL, duration: TimeInterval = 0, resolution: CGSize = .zero) {
        self.id = UUID()
        self.url = url
        self.filename = url.lastPathComponent
        self.duration = duration
        self.resolution = resolution
        self.thumbnailURL = nil
        self.dateAdded = Date()
    }
}
