//
//  MenuBarWindow.swift
//  Harbor
//

import SwiftUI
import AppKit

/// Custom borderless window with vibrancy for native macOS menubar menus
class MenuBarWindow: NSPanel {
    init(contentRect: NSRect, backing: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: backing,
            defer: flag
        )

        // Native macOS Liquid Glass aesthetic
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.level = .popUpMenu
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Vibrancy effect for translucent background
        let visualEffect = NSVisualEffectView()
        visualEffect.material = .menu
        visualEffect.state = .active
        visualEffect.blendingMode = .behindWindow

        self.contentView = visualEffect
    }

    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return false
    }

    /// Position window below status bar button
    func position(below statusBarButton: NSStatusBarButton) {
        guard let buttonWindow = statusBarButton.window else { return }

        let buttonFrame = statusBarButton.convert(statusBarButton.bounds, to: nil)
        let screenFrame = buttonWindow.convertToScreen(buttonFrame)

        // Position below button with slight gap
        let windowOrigin = NSPoint(
            x: screenFrame.midX - frame.width / 2,
            y: screenFrame.minY - frame.height - 8
        )

        setFrameOrigin(windowOrigin)
    }

    /// Show window with native fade-in animation
    func show(below button: NSStatusBarButton) {
        position(below: button)

        // Fade in animation
        alphaValue = 0
        makeKeyAndOrderFront(nil)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            animator().alphaValue = 1.0
        }
    }

    /// Hide window with native fade-out animation
    func hide() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.1
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            animator().alphaValue = 0
        }, completionHandler: {
            self.orderOut(nil)
        })
    }
}

/// Hosting controller that properly embeds SwiftUI content
class MenuBarHostingController: NSHostingController<AnyView> {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
    }
}
