//
//  SettingsViewModelTests.swift
//  HarborTests
//

import XCTest
@testable import Harbor

final class SettingsViewModelTests: XCTestCase {
    @MainActor
    func testLoadSettings() {
        let testDefaults = UserDefaults(suiteName: "com.harbor.test")!
        testDefaults.removePersistentDomain(forName: "com.harbor.test")

        let stateManager = AppStateManager(defaults: testDefaults)
        let viewModel = SettingsViewModel(stateManager: stateManager)

        XCTAssertTrue(viewModel.showBadgeCount)
        XCTAssertFalse(viewModel.launchAtLogin)
    }

    @MainActor
    func testSaveSettings() {
        let testDefaults = UserDefaults(suiteName: "com.harbor.test")!
        testDefaults.removePersistentDomain(forName: "com.harbor.test")

        let stateManager = AppStateManager(defaults: testDefaults)
        let viewModel = SettingsViewModel(stateManager: stateManager)

        viewModel.showBadgeCount = false
        viewModel.launchAtLogin = true

        // Settings should be saved automatically
        let loadedSettings = stateManager.loadSettings()
        XCTAssertFalse(loadedSettings.showBadgeCount)
        XCTAssertTrue(loadedSettings.launchAtLogin)
    }
}
