//
//  PortRowView.swift
//  Harbor
//

import SwiftUI

struct PortRowView: View {
    let portInfo: PortInfo
    let onStop: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            // Active indicator
            Circle()
                .fill(.green)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 4) {
                // Line 1: Folder name and port number with optional buttons
                HStack {
                    Text(portInfo.folderName)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.primary)

                    Spacer()

                    HStack(spacing: 8) {
                        Text(":\(portInfo.port)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)

                        if isHovered {
                            Button(action: {
                                if let url = URL(string: "http://localhost:\(portInfo.port)") {
                                    NSWorkspace.shared.open(url)
                                }
                            }) {
                                Image(systemName: "arrow.up.forward.square")
                                    .font(.system(size: 12))
                            }
                            .buttonStyle(.borderless)
                            .help("Open in browser")

                            Button(action: onStop) {
                                Text("Stop")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .transition(.opacity)
                        }
                    }
                }
            }
        }

                // Line 2: Working directory path
                Text(portInfo.workingDirectory)
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                // Line 3: Process metadata
                HStack(spacing: 4) {
                    Text(portInfo.processName)
                    Text("•")
                    Text(portInfo.command)
                    Text("•")
                    Text(portInfo.formattedUptime)
                }
                .font(.system(size: 11))
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
