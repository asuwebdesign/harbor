//
//  AppSettingsTests.swift
//  HarborTests
//

import XCTest
@testable import Harbor

final class AppSettingsTests: XCTestCase {
    func testDefaultSettings() {
        let settings = AppSettings()

        XCTAssertTrue(settings.showBadgeCount)
        XCTAssertFalse(settings.launchAtLogin)
    }

    func testSettingsCustomization() {
        var settings = AppSettings()
        settings.showBadgeCount = false
        settings.launchAtLogin = true

        XCTAssertFalse(settings.showBadgeCount)
        XCTAssertTrue(settings.launchAtLogin)
    }
}
