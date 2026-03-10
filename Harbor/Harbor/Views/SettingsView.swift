//
//  SettingsView.swift
//  Harbor
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SettingsViewModel.self) private var settingsViewModel

    var body: some View {
        @Bindable var viewModel = settingsViewModel

        VStack(alignment: .leading, spacing: 20) {
            Text("Settings")
                .font(.title2)
                .bold()

            // Settings group with macOS style
            VStack(spacing: 0) {
                // Badge count setting
                HStack {
                    Text("Show badge count in menubar")
                        .font(.system(size: 13))
                    Spacer()
                    Toggle("", isOn: $viewModel.showBadgeCount)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.primary.opacity(0.03))

                Divider()
                    .padding(.leading, 12)

                // Launch at login setting
                HStack {
                    Text("Launch Harbor at login")
                        .font(.system(size: 13))
                    Spacer()
                    Toggle("", isOn: $viewModel.launchAtLogin)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.primary.opacity(0.03))
            }
            .background(Color.primary.opacity(0.03))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
            )

            Spacer()

            HStack {
                Spacer()

                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 420, height: 220)
    }
}

#Preview {
    @Previewable @State var settingsViewModel = SettingsViewModel()

    SettingsView()
        .environment(settingsViewModel)
}
