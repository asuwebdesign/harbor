//
//  AppStateManager.swift
//  Harbor
//

import Foundation
import SwiftUI

@MainActor
final class AppStateManager {
    private let defaults: UserDefaults

    // Update tracking
    @AppStorage("lastUpdateCheckTime") var lastUpdateCheckTime: TimeInterval = 0
    @AppStorage("currentVersion") var currentVersion: String = ""

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadSettings() -> AppSettings {
        var settings = AppSettings()

        // Load settings with defaults
        if defaults.object(forKey: Constants.showBadgeCountKey) != nil {
            settings.showBadgeCount = defaults.bool(forKey: Constants.showBadgeCountKey)
        }

        settings.launchAtLogin = defaults.bool(forKey: Constants.launchAtLoginKey)

        return settings
    }

    func saveSettings(_ settings: AppSettings) {
        defaults.set(settings.showBadgeCount, forKey: Constants.showBadgeCountKey)
        defaults.set(settings.launchAtLogin, forKey: Constants.launchAtLoginKey)
    }

    // MARK: - Update Tracking

    func shouldCheckForUpdates() -> Bool {
        let now = Date().timeIntervalSince1970
        let elapsed = now - lastUpdateCheckTime
        return elapsed >= Constants.updateCheckInterval
    }

    func recordUpdateCheck() {
        lastUpdateCheckTime = Date().timeIntervalSince1970
    }

    func updateCurrentVersion() {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            currentVersion = version
        }
    }
}
