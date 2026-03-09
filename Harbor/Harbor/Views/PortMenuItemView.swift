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
        HStack(spacing: 12) {
            // Active indicator
            Circle()
                .fill(.green)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 6) {
                // Line 1: Folder name and actions
                HStack {
                    Text(portInfo.folderName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)

                    Spacer()

                    HStack(spacing: 8) {
                        if isHovered {
                            Button(action: onOpen) {
                                Text("Open")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)

                            Button(action: onStop) {
                                Text("Stop")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                    .frame(width: 120, alignment: .trailing)
                }

                // Line 2: Port badge
                Text("\(portInfo.port)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.accentColor)
                    .cornerRadius(8)

                // Line 3: Short path
                Text(shortPath)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)

                // Line 4: Process metadata
                HStack(spacing: 4) {
                    Text(portInfo.processName)
                    Text("•")
                    Text(portInfo.command)
                    Text("•")
                    Text(portInfo.formattedUptime)
                }
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
                .lineLimit(1)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .frame(width: 320)
        .background(isHovered ? Color.primary.opacity(0.05) : Color.clear)
        .cornerRadius(6)
        .onHover { hovering in
            isHovered = hovering
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

        hostingView.frame = NSRect(x: 0, y: 0, width: 320, height: 90)
        self.view = hostingView
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
