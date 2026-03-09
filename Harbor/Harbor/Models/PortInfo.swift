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
        let trimmed = workingDirectory.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let components = trimmed.split(separator: "/")
        return String(components.last ?? "Unknown")
    }

    /// Sanitized process name without control characters
    var sanitizedProcessName: String {
        sanitize(processName)
    }

    /// Sanitized command without control characters
    var sanitizedCommand: String {
        sanitize(command)
    }

    /// Sanitized working directory without control characters
    var sanitizedWorkingDirectory: String {
        sanitize(workingDirectory)
    }

    /// Removes control characters and escape sequences from strings
    private func sanitize(_ string: String) -> String {
        // Remove control characters (0x00-0x1F except tab, newline) and DEL (0x7F)
        // Also remove ANSI escape sequences
        let cleaned = string.unicodeScalars.filter { scalar in
            let value = scalar.value
            // Allow printable characters and common whitespace
            return (value >= 0x20 && value != 0x7F) || value == 0x09 || value == 0x0A
        }

        var result = String(String.UnicodeScalarView(cleaned))

        // Remove ANSI escape sequences (ESC[...m or ESC[...;...m etc)
        result = result.replacingOccurrences(
            of: "\\u{001B}\\[[0-9;]*m",
            with: "",
            options: .regularExpression
        )

        // Replace multiple spaces/tabs with single space
        result = result.replacingOccurrences(
            of: "[ \\t]+",
            with: " ",
            options: .regularExpression
        )

        // Trim whitespace
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
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
