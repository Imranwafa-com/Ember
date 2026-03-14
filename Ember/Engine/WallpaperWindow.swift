import AppKit
import AVFoundation

// NSWindow subclass positioned just below Finder's desktop icons, rendering video via AVPlayerLayer in a layer-hosting view. Configured to span all Spaces, ignore mouse events, and never participate in window cycling or fullscreen.
final class WallpaperWindow: NSWindow {

    private(set) var playerLayer: AVPlayerLayer?

    convenience init(screen: NSScreen, player: AVPlayer) {
        self.init(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false,
            screen: screen
        )

        let iconLevel = Int(CGWindowLevelForKey(.desktopIconWindow))
        self.level = NSWindow.Level(rawValue: iconLevel - 1)

        self.collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .ignoresCycle,
            .fullScreenNone
        ]

        self.isOpaque = true
        self.backgroundColor = .black
        self.hasShadow = false
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
        self.ignoresMouseEvents = true
        self.hidesOnDeactivate = false
        self.isReleasedWhenClosed = false

        setupPlayerView(with: player)

        self.displayIfNeeded()
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func resize(to frame: NSRect) {
        setFrame(frame, display: true, animate: false)
        if let contentView = self.contentView {
            playerLayer?.frame = contentView.bounds
        }
    }

    private func setupPlayerView(with player: AVPlayer) {
        let viewFrame = CGRect(origin: .zero, size: self.frame.size)

        let avLayer = AVPlayerLayer(player: player)
        avLayer.frame = viewFrame
        avLayer.videoGravity = .resizeAspectFill
        avLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]

        let rootLayer = CALayer()
        rootLayer.frame = viewFrame
        rootLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        rootLayer.addSublayer(avLayer)

        let view = NSView(frame: viewFrame)
        view.layer = rootLayer
        view.wantsLayer = true
        view.autoresizingMask = [.width, .height]

        self.contentView = view
        self.playerLayer = avLayer
    }
}
