//
//  PortInfo.swift
//  Harbor
//

import Foundation

struct PortInfo: Identifiable {
    let id = UUID()
    let port: Int
    let pid: Int
    let processName: String
    let workingDirectory: String
    let command: String
    let startTime: Date

    /// Extracts the folder name from the working directory path
    var folderName: String {
        let components = workingDirectory.split(separator: "/")
        return String(components.last ?? "Unknown")
    }

    /// Calculates uptime since the process started
    var uptime: TimeInterval {
        Date().timeIntervalSince(startTime)
    }

    /// Formats uptime as human-readable string (e.g., "2h 34m")
    var formattedUptime: String {
        let totalSeconds = Int(uptime)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "\(totalSeconds)s"
        }
    }
}
