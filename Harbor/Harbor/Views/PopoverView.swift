//
//  PopoverView.swift
//  Harbor
//

import SwiftUI

struct PopoverView: View {
    @Environment(PortViewModel.self) private var viewModel
    @State private var showingStopAllAlert = false

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.activePorts.isEmpty {
                EmptyStateView()
                    .frame(height: Constants.popoverMinHeight)
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(viewModel.activePorts) { portInfo in
                            PortRowView(portInfo: portInfo) {
                                Task {
                                    try? await viewModel.stopPort(portInfo)
                                }
                            }

                            if portInfo.id != viewModel.activePorts.last?.id {
                                Divider()
                                    .padding(.horizontal, 12)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .frame(maxHeight: Constants.popoverMaxHeight)

                if viewModel.activePorts.count > 1 {
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
        .frame(width: Constants.popoverWidth)
        .alert("Stop All Servers?", isPresented: $showingStopAllAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Stop All", role: .destructive) {
                Task {
                    await viewModel.stopAllPorts()
                }
            }
        } message: {
            Text("This will stop \(viewModel.activePorts.count) running servers:\n\(viewModel.activePorts.map { $0.folderName }.joined(separator: ", "))")
        }
    }
}

#Preview {
    @Previewable @State var viewModel = PortViewModel()

    PopoverView()
        .environment(viewModel)
        .task {
            // Mock data for preview
            viewModel.activePorts = [
                PortInfo(port: 3000, pid: 1, processName: "node", workingDirectory: "/Users/test/my-app", command: "npm run dev", startTime: Date().addingTimeInterval(-3600)),
                PortInfo(port: 5173, pid: 2, processName: "node", workingDirectory: "/Users/test/vite-app", command: "npm run dev", startTime: Date().addingTimeInterval(-7200))
            ]
        }
}
