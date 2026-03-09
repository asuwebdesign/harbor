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
        didSet { saveSettings() }
    }

    private let stateManager: AppStateManager

    init(stateManager: AppStateManager = AppStateManager()) {
        self.stateManager = stateManager

        let settings = stateManager.loadSettings()
        self.showBadgeCount = settings.showBadgeCount
        self.launchAtLogin = settings.launchAtLogin
    }

    private func saveSettings() {
        let settings = AppSettings(
            showBadgeCount: showBadgeCount,
            launchAtLogin: launchAtLogin
        )
        stateManager.saveSettings(settings)
    }
}
