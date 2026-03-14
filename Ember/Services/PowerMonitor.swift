import Foundation
import Combine
import IOKit.ps

// Monitors power source changes between battery and AC using IOKit RunLoop callbacks, publishing `isOnBattery` on the main thread with no polling.
final class PowerMonitor: ObservableObject {

    @Published var isOnBattery: Bool = false

    private var runLoopSource: CFRunLoopSource?

    func startMonitoring() {
        updatePowerState()

        let context = Unmanaged.passUnretained(self).toOpaque()
        if let source = IOPSNotificationCreateRunLoopSource({ context in
            guard let context else { return }
            let monitor = Unmanaged<PowerMonitor>.fromOpaque(context).takeUnretainedValue()
            DispatchQueue.main.async {
                monitor.updatePowerState()
            }
        }, context)?.takeRetainedValue() {
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
            self.runLoopSource = source
        }
    }

    func stopMonitoring() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .defaultMode)
            runLoopSource = nil
        }
    }

    private func updatePowerState() {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let type = IOPSGetProvidingPowerSourceType(snapshot)?.takeRetainedValue() as? String
        else {
            isOnBattery = false
            return
        }
        isOnBattery = (type == kIOPSBatteryPowerValue as String)
    }
}
