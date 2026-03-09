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
    private var popover: NSPopover!
    private var settingsWindow: NSWindow?
    private let viewModel = PortViewModel()
    private let settingsViewModel = SettingsViewModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create status item in menubar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "building.2.crop.circle", accessibilityDescription: "Harbor")
            button.action = #selector(togglePopover)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        // Create popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: Constants.popoverWidth, height: Constants.popoverMinHeight)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: PopoverView().environment(viewModel))

        // Update badge based on settings
        updateBadge()

        // Observe port changes to update badge
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("PortsDidUpdate"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateBadge()
        }
    }

    @objc func togglePopover(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            showMenu()
        } else {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                if let button = statusItem.button {
                    // Refresh immediately when opening
                    Task {
                        await viewModel.scanPorts()
                        await MainActor.run {
                            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                        }
                    }
                }
            }
        }
    }

    @objc func showMenu() {
        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Harbor", action: #selector(quit), keyEquivalent: "q"))

        statusItem.menu = menu
        statusItem.button?.performClick(nil)

        // Reset menu to nil so left-click still works
        DispatchQueue.main.async {
            self.statusItem.menu = nil
        }
    }

    @objc func openSettings() {
        if settingsWindow == nil {
            let settingsView = SettingsView()
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
