import AppKit
import Combine

// Monitors display sleep, screen lock, and fullscreen app state to determine when wallpaper playback should pause. Publishes `shouldPause` as true when any pause condition is active.
final class ActivityMonitor: ObservableObject {

    @Published var shouldPause: Bool = false

    @Published private var isScreenLocked: Bool = false
    @Published private var isDisplayAsleep: Bool = false
    @Published private var isFullscreenAppActive: Bool = false

    private var cancellables = Set<AnyCancellable>()

    func startMonitoring() {
        let ws = NSWorkspace.shared.notificationCenter
        let dn = DistributedNotificationCenter.default()

        ws.addObserver(self, selector: #selector(displayDidSleep),
                       name: NSWorkspace.screensDidSleepNotification, object: nil)
        ws.addObserver(self, selector: #selector(displayDidWake),
                       name: NSWorkspace.screensDidWakeNotification, object: nil)

        dn.addObserver(self, selector: #selector(screenLocked),
                       name: NSNotification.Name("com.apple.screenIsLocked"), object: nil)
        dn.addObserver(self, selector: #selector(screenUnlocked),
                       name: NSNotification.Name("com.apple.screenIsUnlocked"), object: nil)

        ws.addObserver(self, selector: #selector(activeSpaceChanged),
                       name: NSWorkspace.activeSpaceDidChangeNotification, object: nil)

        Publishers.CombineLatest3($isScreenLocked, $isDisplayAsleep, $isFullscreenAppActive)
            .map { locked, asleep, fullscreen in locked || asleep || fullscreen }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: &$shouldPause)
    }

    func stopMonitoring() {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        DistributedNotificationCenter.default().removeObserver(self)
        cancellables.removeAll()
    }

    @objc private func displayDidSleep(_ n: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.isDisplayAsleep = true
        }
    }

    @objc private func displayDidWake(_ n: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.isDisplayAsleep = false
        }
    }

    @objc private func screenLocked(_ n: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.isScreenLocked = true
        }
    }

    @objc private func screenUnlocked(_ n: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.isScreenLocked = false
        }
    }

    @objc private func activeSpaceChanged(_ n: Notification) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            guard let frontApp = NSWorkspace.shared.frontmostApplication else {
                self.isFullscreenAppActive = false
                return
            }

            let pid = frontApp.processIdentifier

            guard let windowList = CGWindowListCopyWindowInfo(
                [.optionOnScreenOnly, .excludeDesktopElements],
                kCGNullWindowID
            ) as? [[String: Any]] else {
                self.isFullscreenAppActive = false
                return
            }

            self.isFullscreenAppActive = windowList.contains { info in
                guard let ownerPID = info[kCGWindowOwnerPID as String] as? Int32,
                      ownerPID == pid,
                      let boundsDict = info[kCGWindowBounds as String] as? [String: Any],
                      let x = boundsDict["X"] as? CGFloat,
                      let y = boundsDict["Y"] as? CGFloat,
                      let w = boundsDict["Width"] as? CGFloat,
                      let h = boundsDict["Height"] as? CGFloat
                else { return false }

                let windowFrame = CGRect(x: x, y: y, width: w, height: h)
                return NSScreen.screens.contains { screen in
                    windowFrame.contains(screen.frame)
                }
            }
        }
    }
}
