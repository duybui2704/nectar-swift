import Foundation
import Combine

/// Idle session lock — banking standard (PostPay-style ~5 min).
@MainActor
final class SessionLockService: ObservableObject {
    static let shared = SessionLockService()

    @Published private(set) var isLocked = false

    private let idleTimeout: TimeInterval = 5 * 60
    private var lastActivity = Date()
    private var timer: Timer?

    private init() {}

    func startMonitoring() {
        stopMonitoring()
        lastActivity = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    func recordActivity() {
        lastActivity = Date()
        if isLocked { isLocked = false }
    }

    func lockNow() {
        isLocked = true
    }

    func unlock() {
        isLocked = false
        lastActivity = Date()
    }

    private func tick() {
        guard !isLocked else { return }
        if Date().timeIntervalSince(lastActivity) >= idleTimeout {
            isLocked = true
        }
    }
}
