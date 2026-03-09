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
    let onStop: () -> Void

    @State private var isHovered = false

    private var shortPath: String {
        let components = portInfo.workingDirectory.split(separator: "/").map(String.init)
        if components.count >= 2 {
            return "\(components[components.count - 2])/\(components[components.count - 1])"
        } else if components.count == 1 {
            return components[0]
        }
        return portInfo.workingDirectory
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left content
            HStack(spacing: 12) {
                // Active indicator (aligned with title row)
                Circle()
                    .fill(.green)
                    .frame(width: 8, height: 8)
                    .padding(.bottom, 40) // Align with title row

                VStack(alignment: .leading, spacing: 4) {
                    // Line 1: Title and port number
                    HStack {
                        Text(portInfo.folderName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.primary)

                        Spacer()

                        // Port badge
                        Text(String(portInfo.port))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.accentColor)
                            .cornerRadius(8)
                    }

                    // Line 2: Short path
                    Text(shortPath)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary) // Increased contrast from .tertiary
                        .lineLimit(1)

                    // Line 3: Process metadata
                    HStack(spacing: 4) {
                        Text(portInfo.processName)
                        Text("•")
                        Text(portInfo.command)
                        Text("•")
                        Text(portInfo.formattedUptime)
                    }
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary) // Increased contrast from .tertiary
                    .lineLimit(1)
                }
            }
            .frame(width: 240) // Fixed width for content

            Spacer()

            // Right actions (vertically centered, icons only)
            if isHovered {
                HStack(spacing: 6) {
                    Button(action: onOpen) {
                        Image(systemName: "arrow.up.forward.square")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Open in browser")

                    Button(action: onStop) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Stop server")
                }
                .padding(.trailing, 8)
                .transition(.opacity)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .frame(width: 320, height: 70) // Compact height
        .background(isHovered ? Color.primary.opacity(0.05) : Color.clear)
        .cornerRadius(6)
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
    private let onStop: () -> Void

    init(portInfo: PortInfo, onOpen: @escaping () -> Void, onStop: @escaping () -> Void) {
        self.portInfo = portInfo
        self.onOpen = onOpen
        self.onStop = onStop
        super.init(title: "", action: nil, keyEquivalent: "")

        let hostingView = NSHostingView(
            rootView: PortMenuItemView(
                portInfo: portInfo,
                onOpen: onOpen,
                onStop: onStop
            )
        )

        hostingView.frame = NSRect(x: 0, y: 0, width: 320, height: 70)
        self.view = hostingView
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
