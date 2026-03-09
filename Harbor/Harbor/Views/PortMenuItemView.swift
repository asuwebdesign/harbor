//
//  PortMenuItemView.swift
//  Harbor
//

import SwiftUI
import AppKit

/// SwiftUI view for port menu item
struct PortMenuItemView: View {
    let portInfo: PortInfo
    let onOpen: () -> Void
    let onOpenInFinder: () -> Void
    let onStop: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 0) {
            // Left content
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

                        Text(portInfo.folderName)
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
            }
            .frame(width: 240) // Fixed width for content

            Spacer()

            // Right actions (vertically centered, text labels)
            if isHovered {
                HStack(spacing: 8) {
                    Button(action: onOpenInFinder) {
                        Text("Finder")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)

                    Button(action: onStop) {
                        Text("Stop")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                }
                .padding(.trailing, 8)
                .transition(.opacity)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16) // 4px more padding on each side (12 + 4)
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
        )

        hostingView.frame = NSRect(x: 0, y: 0, width: 320, height: 64)
        self.view = hostingView
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
