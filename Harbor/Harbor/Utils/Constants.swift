//
//  Constants.swift
//  Harbor
//

import Foundation

@MainActor
enum Constants {
    // Port Scanning
    nonisolated static let portRangeStart = 3000
    nonisolated static let portRangeEnd = 9000
    nonisolated static let portScanTimeout: TimeInterval = 0.05 // 50ms
    nonisolated static let scanInterval: TimeInterval = 5.0 // 5 seconds

    // UI
    nonisolated static let popoverWidth: CGFloat = 320
    nonisolated static let popoverMinHeight: CGFloat = 200
    nonisolated static let popoverMaxHeight: CGFloat = 500

    // Settings Keys
    nonisolated static let showBadgeCountKey = "showBadgeCount"
    nonisolated static let launchAtLoginKey = "launchAtLogin"

    // GitHub & Updates
    nonisolated static let githubRepoOwner = "markriggan"
    nonisolated static let githubRepoName = "harbor"
    nonisolated static let githubApiBaseURL = "https://api.github.com"
    nonisolated static let updateCheckInterval: TimeInterval = 86400 // 24 hours
}
