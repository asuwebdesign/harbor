//
//  PopoverView.swift
//  Harbor
//

import SwiftUI

enum PopoverTab {
    case ports
    case settings
}

struct PopoverView: View {
    @Environment(PortViewModel.self) private var portViewModel
    @Environment(SettingsViewModel.self) private var settingsViewModel
    @State private var selectedTab: PopoverTab = .ports
    @State private var showingStopAllAlert = false

    // Dynamic height calculation
    private var contentHeight: CGFloat {
        let rowHeight: CGFloat = 90 // Approximate height per row with new layout
        let portCount = portViewModel.activePorts.count
        let maxVisibleRows = 5

        if selectedTab == .settings {
            return 200 // Fixed height for settings
        }

        if portCount == 0 {
            return Constants.popoverMinHeight
        }

        let visibleRows = min(portCount, maxVisibleRows)
        let portsHeight = CGFloat(visibleRows) * rowHeight
        let stopAllButtonHeight: CGFloat = portCount > 1 ? 50 : 0

        return portsHeight + stopAllButtonHeight
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tab Bar
            HStack(spacing: 0) {
                TabButton(title: "Ports", isSelected: selectedTab == .ports) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = .ports
                    }
                }

                TabButton(title: "Settings", isSelected: selectedTab == .settings) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = .settings
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)

            Divider()
                .padding(.top, 8)

            // Content
            Group {
                if selectedTab == .ports {
                    portsContent
                } else {
                    settingsContent
                }
            }
            .frame(height: contentHeight)
            .animation(.easeInOut(duration: 0.2), value: contentHeight)
        }
        .frame(width: Constants.popoverWidth)
        .alert("Stop All Servers?", isPresented: $showingStopAllAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Stop All", role: .destructive) {
                Task {
                    await portViewModel.stopAllPorts()
                }
            }
        } message: {
            Text("This will stop \(portViewModel.activePorts.count) running servers:\n\(portViewModel.activePorts.map { $0.folderName }.joined(separator: ", "))")
        }
    }

    @ViewBuilder
    private var portsContent: some View {
        VStack(spacing: 0) {
            if portViewModel.activePorts.isEmpty {
                EmptyStateView()
                    .frame(height: Constants.popoverMinHeight)
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(portViewModel.activePorts) { portInfo in
                            PortRowView(portInfo: portInfo) {
                                Task {
                                    try? await portViewModel.stopPort(portInfo)
                                }
                            }

                            if portInfo.id != portViewModel.activePorts.last?.id {
                                Divider()
                                    .padding(.horizontal, 12)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                if portViewModel.activePorts.count > 1 {
                    Divider()

                    Button("Stop All") {
                        showingStopAllAlert = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    .padding(.vertical, 12)
                }
            }
        }
    }

    @ViewBuilder
    private var settingsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 16) {
                Toggle("Show badge count in menubar", isOn: Binding(
                    get: { settingsViewModel.showBadgeCount },
                    set: { settingsViewModel.showBadgeCount = $0 }
                ))

                Toggle("Launch Harbor at login", isOn: Binding(
                    get: { settingsViewModel.launchAtLogin },
                    set: { settingsViewModel.launchAtLogin = $0 }
                ))
            }

            Spacer()
        }
        .padding(20)
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? .primary : .secondary)

                Rectangle()
                    .fill(isSelected ? Color.accentColor : Color.clear)
                    .frame(height: 2)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }
}

#Preview {
    @Previewable @State var portViewModel = PortViewModel()
    @Previewable @State var settingsViewModel = SettingsViewModel()

    PopoverView()
        .environment(portViewModel)
        .environment(settingsViewModel)
        .task {
            // Mock data for preview
            portViewModel.activePorts = [
                PortInfo(port: 3000, pid: 1, processName: "node", workingDirectory: "/Users/test/my-app", command: "npm run dev", startTime: Date().addingTimeInterval(-3600)),
                PortInfo(port: 5173, pid: 2, processName: "node", workingDirectory: "/Users/test/vite-app", command: "npm run dev", startTime: Date().addingTimeInterval(-7200))
            ]
        }
}
