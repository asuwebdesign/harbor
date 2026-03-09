//
//  AboutView.swift
//  Harbor
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            // App Icon
            if let appIcon = NSImage(named: "AppIcon") {
                Image(nsImage: appIcon)
                    .resizable()
                    .frame(width: 80, height: 80)
                    .cornerRadius(16)
            }

            // App Name
            Text("Harbor")
                .font(.system(size: 24, weight: .bold))

            // Version
            Text("Version 1.0.0")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            // Author
            Text("by Mark Riggan")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            Spacer()
                .frame(height: 8)
        }
        .padding(32)
        .frame(width: 280, height: 260)
    }
}
