//
//  PortRowView.swift
//  Harbor
//

import SwiftUI

struct PortRowView: View {
    let portInfo: PortInfo
    let onStop: () -> Void

    @State private var isHovered = false
    @State private var scrollOffset: CGFloat = 0
    @State private var needsScrolling = false

    var body: some View {
        HStack(spacing: 12) {
            // Active indicator
            Circle()
                .fill(.green)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 4) {
                // Line 1: Folder name (reduced font size)
                HStack {
                    Text(portInfo.folderName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)

                    Spacer()

                    if isHovered {
                        Button(action: {
                            if let url = URL(string: "http://localhost:\(portInfo.port)") {
                                NSWorkspace.shared.open(url)
                            }
                        }) {
                            Text("Open")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .help("Open in browser")

                        Button(action: onStop) {
                            Text("Stop")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .transition(.opacity)
                    }
                }

                // Line 2: Port number (fixed position, no shifting)
                Text(":\(portInfo.port)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)

                // Line 3: Working directory path with ticker scroll
                GeometryReader { geometry in
                    Text(portInfo.workingDirectory)
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .fixedSize()
                        .offset(x: isHovered && needsScrolling ? scrollOffset : 0)
                        .background(
                            GeometryReader { textGeometry in
                                Color.clear.onAppear {
                                    needsScrolling = textGeometry.size.width > geometry.size.width
                                }
                            }
                        )
                }
                .frame(height: 14)
                .clipped()

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
        .background(isHovered ? Color.primary.opacity(0.05) : Color.clear)
        .cornerRadius(6)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }

            if hovering && needsScrolling {
                // Start ticker animation
                withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: true)) {
                    scrollOffset = -100 // Scroll left
                }
            } else {
                // Reset position
                withAnimation(.easeOut(duration: 0.3)) {
                    scrollOffset = 0
                }
            }
        }
    }
}

#Preview {
    PortRowView(
        portInfo: PortInfo(
            port: 3000,
            pid: 12345,
            processName: "node",
            workingDirectory: "/Users/test/projects/my-app",
            command: "npm run dev",
            startTime: Date().addingTimeInterval(-7200)
        ),
        onStop: {}
    )
    .frame(width: 320)
    .padding()
}
