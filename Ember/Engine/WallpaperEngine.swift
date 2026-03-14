import AVFoundation
import Combine
import AppKit
import QuartzCore

// Core playback orchestrator managing AVQueuePlayer loops, boomerang mode, speed control, idle detection, and Combine-based pause logic across power, activity, and user state. Shares a single decode pipeline across all displays via ScreenManager.
@MainActor
final class WallpaperEngine: ObservableObject {

    @Published var isPlaying: Bool = false
    @Published var currentWallpaper: Wallpaper?
    @Published var userPaused: Bool = false

    private var player: AVQueuePlayer?
    private var playerLooper: AVPlayerLooper?
    private let screenManager = ScreenManager()
    private let settings = AppSettings.shared
    private var cancellables = Set<AnyCancellable>()
    private var activityToken: NSObjectProtocol?
    private var statusObserver: NSKeyValueObservation?

    private var boomerangForwardItem: AVPlayerItem?
    private var boomerangReverseItem: AVPlayerItem?
    private var endOfItemObserver: NSObjectProtocol?

    private var idleTimer: Timer?

    var powerMonitor: PowerMonitor?
    var activityMonitor: ActivityMonitor?

    init() {}

    func apply(wallpaper: Wallpaper) {
        tearDown()

        self.currentWallpaper = wallpaper
        settings.selectedWallpaperURL = wallpaper.url.path

        if settings.boomerangMode {
            setupBoomerangPlayback(url: wallpaper.url)
        } else {
            setupLoopingPlayback(url: wallpaper.url)
        }

        player?.rate = settings.playbackSpeed

        if let queuePlayer = player {
            screenManager.configureWindows(with: queuePlayer)
        }

        isPlaying = true
        beginActivity()
        bindPauseLogic()
        startIdleDetection()
    }

    private func setupLoopingPlayback(url: URL) {
        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        item.preferredForwardBufferDuration = 2.0

        let queuePlayer = AVQueuePlayer()
        queuePlayer.isMuted = true
        queuePlayer.preventsDisplaySleepDuringVideoPlayback = false

        let looper = AVPlayerLooper(player: queuePlayer, templateItem: item)

        self.player = queuePlayer
        self.playerLooper = looper

        observeItemStatus(item)

        queuePlayer.play()
    }

    private func setupBoomerangPlayback(url: URL) {
        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        item.preferredForwardBufferDuration = 2.0

        let queuePlayer = AVQueuePlayer(items: [item])
        queuePlayer.isMuted = true
        queuePlayer.preventsDisplaySleepDuringVideoPlayback = false

        self.player = queuePlayer
        self.boomerangForwardItem = item

        observeItemStatus(item)

        endOfItemObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self,
                  let player = self.player,
                  let currentItem = player.currentItem else { return }

            let duration = currentItem.duration
            guard duration.isValid && !duration.isIndefinite else { return }

            player.pause()
            currentItem.seek(to: duration, completionHandler: { finished in
                guard finished else { return }
                DispatchQueue.main.async {
                    player.rate = -abs(self.settings.playbackSpeed)

                    let startTime = CMTime(seconds: 0.05, preferredTimescale: 600)
                    player.addBoundaryTimeObserver(
                        forTimes: [NSValue(time: startTime)],
                        queue: .main
                    ) { [weak self] in
                        guard let self, let player = self.player else { return }
                        player.pause()
                        player.currentItem?.seek(to: .zero) { finished in
                            guard finished else { return }
                            DispatchQueue.main.async {
                                player.rate = abs(self.settings.playbackSpeed)
                            }
                        }
                    }
                }
            })
        }

        queuePlayer.play()
    }

    private func observeItemStatus(_ item: AVPlayerItem) {
        statusObserver = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                switch item.status {
                case .readyToPlay:
                    if !self.userPaused {
                        self.player?.rate = self.settings.playbackSpeed
                        self.isPlaying = true
                    }
                case .failed:
                    print("[Ember] Failed to load video: \(item.error?.localizedDescription ?? "unknown")")
                default:
                    break
                }
            }
        }
    }

    func updateSpeed(_ speed: Float) {
        settings.playbackSpeed = speed
        if isPlaying {
            player?.rate = speed
        }
    }

    func toggleBoomerang(_ enabled: Bool) {
        settings.boomerangMode = enabled
        if let wallpaper = currentWallpaper {
            apply(wallpaper: wallpaper)
        }
    }

    func togglePause() {
        userPaused.toggle()
        if userPaused {
            player?.pause()
            isPlaying = false
            endActivity()
        } else {
            player?.rate = settings.playbackSpeed
            isPlaying = true
            beginActivity()
        }
    }

    func tearDown() {
        idleTimer?.invalidate()
        idleTimer = nil
        if let observer = endOfItemObserver {
            NotificationCenter.default.removeObserver(observer)
            endOfItemObserver = nil
        }
        statusObserver?.invalidate()
        statusObserver = nil
        player?.pause()
        isPlaying = false
        endActivity()
        screenManager.tearDown()
        playerLooper?.disableLooping()
        playerLooper = nil
        player = nil
        currentWallpaper = nil
        boomerangForwardItem = nil
        boomerangReverseItem = nil
        cancellables.removeAll()
    }

    private func startIdleDetection() {
        idleTimer?.invalidate()
        let idleMinutes = settings.pauseAfterIdleMinutes
        guard idleMinutes > 0 else { return }

        idleTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self else { return }
                let idleSeconds = self.systemIdleTime()
                let threshold = Double(self.settings.pauseAfterIdleMinutes) * 60.0

                if idleSeconds >= threshold {
                    if self.isPlaying && !self.userPaused {
                        self.player?.pause()
                        self.isPlaying = false
                        self.endActivity()
                    }
                } else {
                    if !self.isPlaying && !self.userPaused && self.player != nil {
                        self.player?.rate = self.settings.playbackSpeed
                        self.isPlaying = true
                        self.beginActivity()
                    }
                }
            }
        }
    }

    private nonisolated func systemIdleTime() -> TimeInterval {
        var iterator: io_iterator_t = 0
        let result = IOServiceGetMatchingServices(
            kIOMainPortDefault,
            IOServiceMatching("IOHIDSystem"),
            &iterator
        )
        guard result == KERN_SUCCESS else { return 0 }
        defer { IOObjectRelease(iterator) }

        let entry = IOIteratorNext(iterator)
        guard entry != 0 else { return 0 }
        defer { IOObjectRelease(entry) }

        var unmanagedDict: Unmanaged<CFMutableDictionary>?
        let kr = IORegistryEntryCreateCFProperties(entry, &unmanagedDict, kCFAllocatorDefault, 0)
        guard kr == KERN_SUCCESS, let dict = unmanagedDict?.takeRetainedValue() as? [String: Any] else {
            return 0
        }

        if let idleNS = dict["HIDIdleTime"] as? Int64 {
            return TimeInterval(idleNS) / 1_000_000_000.0
        }
        return 0
    }

    private func bindPauseLogic() {
        guard let powerMonitor = powerMonitor,
              let activityMonitor = activityMonitor else { return }

        Publishers.CombineLatest3(
            powerMonitor.$isOnBattery,
            activityMonitor.$shouldPause,
            $userPaused
        )
        .dropFirst()
        .map { [weak self] onBattery, activityPause, userPaused -> Bool in
            guard let self else { return false }
            if userPaused { return false }
            if activityPause { return false }
            if onBattery && self.settings.pauseOnBattery { return false }
            return true
        }
        .removeDuplicates()
        .receive(on: DispatchQueue.main)
        .sink { [weak self] shouldPlay in
            guard let self, self.player != nil else { return }
            if shouldPlay {
                self.player?.rate = self.settings.playbackSpeed
                self.isPlaying = true
                self.beginActivity()
            } else {
                self.player?.pause()
                self.isPlaying = false
                self.endActivity()
            }
        }
        .store(in: &cancellables)
    }

    private func beginActivity() {
        guard activityToken == nil else { return }
        activityToken = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiated, .idleDisplaySleepDisabled],
            reason: "Playing animated wallpaper"
        )
    }

    private func endActivity() {
        if let token = activityToken {
            ProcessInfo.processInfo.endActivity(token)
            activityToken = nil
        }
    }
}
