//
//  AppStateManager.swift
//  Harbor
//

import Foundation

@Observable
final class AppStateManager {
    private let defaults: UserDefaults

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
}
