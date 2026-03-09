//
//  SettingsView.swift
//  Harbor
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Settings")
                .font(.title2)
                .bold()

            VStack(alignment: .leading, spacing: 16) {
                Toggle("Show badge count in menubar", isOn: $viewModel.showBadgeCount)

                Toggle("Launch Harbor at login", isOn: $viewModel.launchAtLogin)
            }

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
        .frame(width: 350, height: 180)
    }
}

#Preview {
    SettingsView()
}
