//
//  SettingsViewModel.swift
//  Harbor
//

import Foundation
import SwiftUI

@Observable
@MainActor
final class SettingsViewModel {
    var showBadgeCount: Bool {
        didSet { saveSettings() }
    }

    var launchAtLogin: Bool {
        didSet {
            saveSettings()

            // Update launch at login status
            do {
                if launchAtLogin {
                    try LaunchAtLogin.enable()
                } else {
                    try LaunchAtLogin.disable()
                }
            } catch {
                print("Failed to update launch at login: \(error)")
                // Revert on failure
                launchAtLogin = LaunchAtLogin.isEnabled()
            }
        }
    }

    private let stateManager: AppStateManager

    init(stateManager: AppStateManager? = nil) {
        self.stateManager = stateManager ?? AppStateManager()

        let settings = self.stateManager.loadSettings()
        self.showBadgeCount = settings.showBadgeCount

        // Get actual launch at login status from system
        self.launchAtLogin = LaunchAtLogin.isEnabled()
    }

    private func saveSettings() {
        let settings = AppSettings(
            showBadgeCount: showBadgeCount,
            launchAtLogin: launchAtLogin
        )
        stateManager.saveSettings(settings)

        // Notify observers that settings changed
        NotificationCenter.default.post(name: NSNotification.Name("SettingsDidUpdate"), object: nil)
    }
}
