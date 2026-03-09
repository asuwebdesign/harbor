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
    private var menuBarWindow: MenuBarWindow!
    private var eventMonitor: Any?
    private var settingsWindow: NSWindow?
    private let viewModel = PortViewModel()
    private let settingsViewModel = SettingsViewModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create status item in menubar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "building.2.crop.circle", accessibilityDescription: "Harbor")
            button.action = #selector(toggleMenu)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        // Create native menubar window with Liquid Glass aesthetic
        let windowRect = NSRect(x: 0, y: 0, width: Constants.popoverWidth, height: Constants.popoverMinHeight)
        menuBarWindow = MenuBarWindow(
            contentRect: windowRect,
            backing: .buffered,
            defer: false
        )

        // Embed SwiftUI content
        let hostingView = MenuBarHostingController(
            rootView: AnyView(
                PopoverView()
                    .environment(viewModel)
                    .environment(settingsViewModel)
            )
        )

        if let visualEffectView = menuBarWindow.contentView as? NSVisualEffectView {
            hostingView.view.frame = visualEffectView.bounds
            hostingView.view.autoresizingMask = [.width, .height]
            visualEffectView.addSubview(hostingView.view)
        }

        // Monitor clicks outside window to dismiss
        setupEventMonitor()

        // Update badge based on settings
        Task { @MainActor in
            updateBadge()
        }

        // Observe port changes to update badge
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("PortsDidUpdate"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
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

    @objc func toggleMenu(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            if menuBarWindow.isVisible {
                hideMenu()
            } else {
                showMenu()
            }
        }
    }

    private func showMenu() {
        guard let button = statusItem.button else { return }

        // Refresh ports before showing
        Task {
            await viewModel.scanPorts()
            await MainActor.run {
                menuBarWindow.show(below: button)
            }
        }
    }

    private func hideMenu() {
        menuBarWindow.hide()
    }

    private func setupEventMonitor() {
        // Monitor for clicks outside the window
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, self.menuBarWindow.isVisible else { return }

            // Check if click is outside the window
            let clickLocation = event.locationInWindow
            let windowFrame = self.menuBarWindow.frame

            if !NSPointInRect(NSEvent.mouseLocation, windowFrame) {
                self.hideMenu()
            }
        }
    }

    @objc func showContextMenu() {
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

    deinit {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
