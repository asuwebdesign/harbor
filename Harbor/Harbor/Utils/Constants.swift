//
//  Constants.swift
//  Harbor
//

import Foundation

enum Constants {
    // Port Scanning
    static let portRangeStart = 3000
    static let portRangeEnd = 9000
    static let portScanTimeout: TimeInterval = 0.05 // 50ms
    static let scanInterval: TimeInterval = 5.0 // 5 seconds

    // UI
    static let popoverWidth: CGFloat = 320
    static let popoverMinHeight: CGFloat = 200
    static let popoverMaxHeight: CGFloat = 500

    // Settings Keys
    static let showBadgeCountKey = "showBadgeCount"
    static let launchAtLoginKey = "launchAtLogin"
}
