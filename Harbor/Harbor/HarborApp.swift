//
//  HarborApp.swift
//  Harbor
//

import SwiftUI
import AppKit

@main
struct HarborApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var settingsWindow: NSWindow?
    private var aboutWindow: NSWindow?
    private let viewModel = PortViewModel()
    private let settingsViewModel = SettingsViewModel()
    private let updateChecker = UpdateCheckerService()
    private var updateMenuItemTitle = "Checking for updates..."
    private var updateMenuItemEnabled = false
    private var latestRelease: GitHubRelease?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create status item in menubar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = AnchorIcon.create(size: CGSize(width: 18, height: 18))
            button.action = #selector(handleMenuBarClick)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        // Build initial menu
        buildMenu()

        // Update badge based on settings
        Task { @MainActor in
            updateBadge()
        }

        // Observe port changes to rebuild menu and update badge
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("PortsDidUpdate"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.buildMenu()
                self?.updateBadge()
            }
        }

        // Observe settings changes to update badge
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SettingsDidUpdate"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.updateBadge()
            }
        }

        // Check for updates after short delay
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            await checkForUpdates()
        }
    }

    @objc func handleMenuBarClick() {
        // Refresh ports before showing menu
        Task {
            await viewModel.scanPorts()
            await MainActor.run {
                buildMenu()
                if let button = statusItem.button {
                    statusItem.menu?.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height), in: button)
                }
            }
        }
    }

    private func buildMenu() {
        let menu = NSMenu()

        // Add heading
        if !viewModel.activePorts.isEmpty {
            let headingItem = NSMenuItem(title: "ACTIVE SERVERS", action: nil, keyEquivalent: "")
            headingItem.isEnabled = false

            // Style the heading
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 11, weight: .semibold),
                .foregroundColor: NSColor.secondaryLabelColor
            ]
            headingItem.attributedTitle = NSAttributedString(string: "ACTIVE SERVERS", attributes: attributes)

            menu.addItem(headingItem)
        }

        // Add port items
        if viewModel.activePorts.isEmpty {
            let emptyItem = NSMenuItem(title: "No active ports", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        } else {
            for portInfo in viewModel.activePorts {
                let portItem = PortMenuItem(
                    portInfo: portInfo,
                    onOpen: { [weak self] in
                        if let url = URL(string: "http://localhost:\(portInfo.port)") {
                            NSWorkspace.shared.open(url)
                        }
                        self?.statusItem.menu = nil
                    },
                    onOpenInFinder: { [weak self] in
                        let url = URL(fileURLWithPath: portInfo.workingDirectory)
                        NSWorkspace.shared.open(url)
                        self?.statusItem.menu = nil
                    },
                    onStop: { [weak self] in
                        Task {
                            try? await self?.viewModel.stopPort(portInfo)
                        }
                        self?.statusItem.menu = nil
                    }
                )
                menu.addItem(portItem)
            }

            // Add Stop All if multiple ports
            if viewModel.activePorts.count > 1 {
                menu.addItem(NSMenuItem.separator())

                let stopAllItem = NSMenuItem(
                    title: "Stop All (\(viewModel.activePorts.count) servers)",
                    action: #selector(stopAllPorts),
                    keyEquivalent: ""
                )
                stopAllItem.target = self
                stopAllItem.image = NSImage(systemSymbolName: "stop.fill", accessibilityDescription: "Stop All")
                menu.addItem(stopAllItem)
            }
        }

        // Separator before update item
        menu.addItem(NSMenuItem.separator())

        // Update menu item (dynamic)
        let updateItem = NSMenuItem(
            title: updateMenuItemTitle,
            action: updateMenuItemEnabled ? #selector(showUpdateDialog) : nil,
            keyEquivalent: ""
        )
        updateItem.isEnabled = updateMenuItemEnabled
        if !updateMenuItemEnabled {
            // Gray out disabled items
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 13),
                .foregroundColor: NSColor.secondaryLabelColor
            ]
            updateItem.attributedTitle = NSAttributedString(string: updateMenuItemTitle, attributes: attributes)
        }
        menu.addItem(updateItem)

        menu.addItem(NSMenuItem.separator())

        // Settings
        let settingsItem = NSMenuItem(
            title: "Settings...",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        // About
        let aboutItem = NSMenuItem(
            title: "About Harbor",
            action: #selector(showAbout),
            keyEquivalent: ""
        )
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(
            title: "Quit Harbor",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu

        // Set delegate to reset menu after it closes
        menu.delegate = self
    }

    @objc func stopAllPorts() {
        // Show confirmation alert
        let alert = NSAlert()
        alert.messageText = "Stop All Servers?"
        alert.informativeText = "This will stop \(viewModel.activePorts.count) running servers:\n\(viewModel.activePorts.map { $0.folderName }.joined(separator: ", "))"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Stop All")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            Task { @MainActor in
                await viewModel.stopAllPorts()
            }
        }
    }

    @objc func openSettings() {
        if settingsWindow == nil {
            let settingsView = SettingsView()
                .environment(settingsViewModel)
            let hostingController = NSHostingController(rootView: settingsView)

            let window = NSWindow(contentViewController: hostingController)
            window.title = "Harbor Settings"
            window.styleMask = [.titled, .closable]
            window.level = .floating

            settingsWindow = window
        }

        // Center on screen every time it's shown
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let windowFrame = settingsWindow!.frame
            let x = screenFrame.midX - windowFrame.width / 2
            let y = screenFrame.midY - windowFrame.height / 2
            settingsWindow?.setFrameOrigin(NSPoint(x: x, y: y))
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func showAbout() {
        if aboutWindow == nil {
            let aboutView = AboutView()
            let hostingController = NSHostingController(rootView: aboutView)

            let window = NSWindow(contentViewController: hostingController)
            window.title = "About Harbor"
            window.styleMask = [.titled, .closable]
            window.level = .floating

            aboutWindow = window
        }

        // Center on screen every time it's shown
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let windowFrame = aboutWindow!.frame
            let x = screenFrame.midX - windowFrame.width / 2
            let y = screenFrame.midY - windowFrame.height / 2
            aboutWindow?.setFrameOrigin(NSPoint(x: x, y: y))
        }

        aboutWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func quit() {
        NSApp.terminate(nil)
    }

    @MainActor
    private func updateBadge() {
        guard let button = statusItem.button else { return }

        if settingsViewModel.showBadgeCount && !viewModel.activePorts.isEmpty {
            // Use system font for proper menubar alignment
            let count = String(viewModel.activePorts.count)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: NSFont.systemFontSize),
                .baselineOffset: -2 // Lower by 2 pixels for better vertical alignment
            ]
            button.attributedTitle = NSAttributedString(string: " \(count)", attributes: attributes)
        } else {
            button.attributedTitle = NSAttributedString(string: "")
        }
    }

    @MainActor
    private func checkForUpdates() async {
        // Only check if cooldown period has passed
        guard AppStateManager.shared.shouldCheckForUpdates() else {
            updateMenuItemTitle = "You're up to date"
            updateMenuItemEnabled = false
            return
        }

        let result = await updateChecker.checkForUpdates()

        switch result {
        case .updateAvailable(let release):
            updateMenuItemTitle = "Update Available - Version \(release.version)"
            updateMenuItemEnabled = true
            latestRelease = release
            AppStateManager.shared.recordUpdateCheck()

        case .upToDate:
            updateMenuItemTitle = "You're up to date"
            updateMenuItemEnabled = false
            AppStateManager.shared.recordUpdateCheck()

        case .error:
            // Silent failure - show up to date
            updateMenuItemTitle = "You're up to date"
            updateMenuItemEnabled = false
        }
    }

    @MainActor
    @objc private func showUpdateDialog() {
        guard let release = latestRelease else { return }

        let alert = NSAlert()
        alert.messageText = "Harbor \(release.version) is Available"
        alert.informativeText = release.truncatedBody()
        alert.alertStyle = .informational
        alert.addButton(withTitle: "View Release")
        alert.addButton(withTitle: "Later")

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            // Open GitHub release page in browser
            if let url = URL(string: release.htmlUrl) {
                NSWorkspace.shared.open(url)
            }
        }
    }
}

// MARK: - NSMenuDelegate
extension AppDelegate: NSMenuDelegate {
    func menuDidClose(_ menu: NSMenu) {
        // Reset menu to nil after it closes so we can rebuild next time
        statusItem.menu = nil
    }
}
