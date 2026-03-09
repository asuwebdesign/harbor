//
//  AppStateManagerTests.swift
//  HarborTests
//

import XCTest
@testable import Harbor

final class AppStateManagerTests: XCTestCase {
    var manager: AppStateManager!
    let testDefaults = UserDefaults(suiteName: "com.harbor.test")!

    override func setUp() {
        super.setUp()
        testDefaults.removePersistentDomain(forName: "com.harbor.test")
        manager = AppStateManager(defaults: testDefaults)
    }

    func testLoadDefaultSettings() {
        let settings = manager.loadSettings()

        XCTAssertTrue(settings.showBadgeCount)
        XCTAssertFalse(settings.launchAtLogin)
    }

    func testSaveAndLoadSettings() {
        var settings = AppSettings()
        settings.showBadgeCount = false
        settings.launchAtLogin = true

        manager.saveSettings(settings)
        let loadedSettings = manager.loadSettings()

        XCTAssertFalse(loadedSettings.showBadgeCount)
        XCTAssertTrue(loadedSettings.launchAtLogin)
    }

    func testSettingsPersistence() {
        var settings = AppSettings()
        settings.showBadgeCount = false
        manager.saveSettings(settings)

        // Create new manager with same defaults
        let newManager = AppStateManager(defaults: testDefaults)
        let loadedSettings = newManager.loadSettings()

        XCTAssertFalse(loadedSettings.showBadgeCount)
    }
}
