//
//  PortMenuItemView.swift
//  Harbor
//

import SwiftUI
import AppKit

/// Custom button style for hover actions with subtle hover effect
struct HoverActionButtonStyle: ButtonStyle {
    @State private var isHovering = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isHovering ? Color.primary.opacity(0.08) : Color.clear)
            )
            .cornerRadius(4)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isHovering = hovering
                }
            }
    }
}

/// SwiftUI view for port menu item
struct PortMenuItemView: View {
    let portInfo: PortInfo
    let onOpen: () -> Void
    let onOpenInFinder: () -> Void
    let onStop: () -> Void

    @State private var isHovered = false

    var body: some View {
        ZStack(alignment: .trailing) {
            // Main content
            HStack(spacing: 12) {
                // Active indicator (aligned with title row)
                Circle()
                    .fill(.green)
                    .frame(width: 8, height: 8)
                    .padding(.bottom, 36) // Align with title row

                VStack(alignment: .leading, spacing: 4) {
                    // Line 1: Port number and title
                    HStack(spacing: 8) {
                        // Port badge
                        Text(String(portInfo.port))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.accentColor)
                            .cornerRadius(8)

                        Text(portInfo.sanitizedFolderName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.primary)

                        Spacer()
                    }

                    // Line 2: Command
                    Text(portInfo.sanitizedCommand)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    // Line 3: Duration
                    Text(portInfo.formattedUptime)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            // Overlay buttons (only shown on hover)
            if isHovered {
                VStack(spacing: 4) {
                    Button(action: onOpenInFinder) {
                        HStack(spacing: 4) {
                            FolderIcon()
                            Text("Finder")
                                .font(.system(size: 11))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(HoverActionButtonStyle())

                    Button(action: onStop) {
                        HStack(spacing: 4) {
                            StopCircleIcon()
                            Text("Stop")
                                .font(.system(size: 11))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(HoverActionButtonStyle())
                }
                .padding(.trailing, 4)
                .transition(.opacity)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .frame(width: 320, height: 64) // Height for 3 lines
        .background(isHovered ? Color.primary.opacity(0.05) : Color.clear)
        .cornerRadius(6)
        .contentShape(Rectangle()) // Make entire area clickable
        .onTapGesture {
            onOpen()
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

/// NSMenuItem with SwiftUI hosting view for port display
class PortMenuItem: NSMenuItem {
    private let portInfo: PortInfo
    private let onOpen: () -> Void
    private let onOpenInFinder: () -> Void
    private let onStop: () -> Void

    init(portInfo: PortInfo, onOpen: @escaping () -> Void, onOpenInFinder: @escaping () -> Void, onStop: @escaping () -> Void) {
        self.portInfo = portInfo
        self.onOpen = onOpen
        self.onOpenInFinder = onOpenInFinder
        self.onStop = onStop
        super.init(title: "", action: nil, keyEquivalent: "")

        let hostingView = NSHostingView(
            rootView: PortMenuItemView(
                portInfo: portInfo,
                onOpen: onOpen,
                onOpenInFinder: onOpenInFinder,
                onStop: onStop
            )
            .padding(.horizontal, 8) // 8px margin on each side to match other menu items
        )

        hostingView.frame = NSRect(x: 0, y: 0, width: 336, height: 64) // 320 + 16 for margins
        self.view = hostingView
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
