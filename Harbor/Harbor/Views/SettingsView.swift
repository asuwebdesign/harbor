//
//  SettingsView.swift
//  Harbor
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SettingsViewModel.self) private var viewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 24) {
                Text("Settings")
                    .font(.title2)
                    .bold()
                    .padding(.top, 4)

                VStack(alignment: .leading, spacing: 16) {
                    Toggle("Show badge count in menubar", isOn: $viewModel.showBadgeCount)

                    Toggle("Launch Harbor at login", isOn: $viewModel.launchAtLogin)
                }
            }

            Spacer()

            HStack {
                Spacer()

                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.bottom, 4)
        }
        .padding(24)
        .frame(width: 350, height: 200)
    }
}

#Preview {
    @Previewable @State var settingsViewModel = SettingsViewModel()

    SettingsView()
        .environment(settingsViewModel)
}
