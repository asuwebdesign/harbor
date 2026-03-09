//
//  SettingsView.swift
//  Harbor
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
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
        .padding(20)
        .frame(width: 300, height: 150)
    }
}

#Preview {
    SettingsView()
}
