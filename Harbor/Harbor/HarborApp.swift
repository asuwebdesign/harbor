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

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var settingsWindow: NSWindow?
    private let viewModel = PortViewModel()
    private let settingsViewModel = SettingsViewModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create status item in menubar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "building.2.crop.circle", accessibilityDescription: "Harbor")
            button.action = #selector(showMenu)
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
    }

    @objc func showMenu() {
        // Refresh ports before showing menu
        Task {
            await viewModel.scanPorts()
            await MainActor.run {
                buildMenu()
                statusItem.button?.performClick(nil)
            }
        }
    }

    private func buildMenu() {
        let menu = NSMenu()

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
                menu.addItem(stopAllItem)
            }
        }

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

        // Reset menu to nil after it's shown so we can rebuild next time
        DispatchQueue.main.async {
            self.statusItem.menu = nil
        }
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
            Task {
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
            window.center()

            settingsWindow = window
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func showAbout() {
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "Harbor",
            .applicationVersion: "1.0.0",
            .credits: NSAttributedString(string: "A native macOS menubar app for managing localhost development servers")
        ])
    }

    @objc func quit() {
        NSApp.terminate(nil)
    }

    @MainActor
    private func updateBadge() {
        guard let button = statusItem.button else { return }

        if settingsViewModel.showBadgeCount && !viewModel.activePorts.isEmpty {
            button.title = " \(viewModel.activePorts.count)"
        } else {
            button.title = ""
        }
    }
}
