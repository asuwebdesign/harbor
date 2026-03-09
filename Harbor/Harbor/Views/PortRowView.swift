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
    @State private var isScrolling = false

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
                // Line 1: Folder name and actions (fixed width to prevent shift)
                HStack {
                    Text(portInfo.folderName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)

                    Spacer()

                    // Fixed-width container for actions to prevent layout shift
                    HStack(spacing: 8) {
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
                        }
                    }
                    .frame(width: 120, alignment: .trailing) // Fixed width prevents shift
                }

                // Line 2: Port number as badge
                HStack(spacing: 6) {
                    Text("\(portInfo.port)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.accentColor)
                        .cornerRadius(8)
                }

                // Line 3: Shortened directory path with ticker scroll
                GeometryReader { geometry in
                    Text(shortPath)
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .offset(x: isScrolling ? scrollOffset : 0)
                        .onAppear {
                            if isHovered {
                                startScrollAnimation(containerWidth: geometry.size.width)
                            }
                        }
                        .onChange(of: isHovered) { _, newValue in
                            if newValue {
                                startScrollAnimation(containerWidth: geometry.size.width)
                            } else {
                                stopScrollAnimation()
                            }
                        }
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
            isHovered = hovering
        }
    }

    private func startScrollAnimation(containerWidth: CGFloat) {
        // Only scroll if text is wider than container
        let textWidth = shortPath.count * 7 // Rough estimate
        if textWidth > Int(containerWidth) {
            isScrolling = true
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: true)) {
                scrollOffset = -CGFloat(textWidth - Int(containerWidth))
            }
        }
    }

    private func stopScrollAnimation() {
        isScrolling = false
        withAnimation(.easeOut(duration: 0.3)) {
            scrollOffset = 0
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
