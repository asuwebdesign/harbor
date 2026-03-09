//
//  ProcessService.swift
//  Harbor
//

import Foundation

actor ProcessService {
    /// Checks if a process can be safely killed (owned by current user)
    func canKillProcess(pid: Int32) -> Bool {
        guard pid > 0 else { return false }

        // Check if process exists and is owned by current user
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-p", "\(pid)", "-o", "user="]

        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()

            guard process.terminationStatus == 0 else { return false }

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            let currentUser = NSUserName()
            return output == currentUser
        } catch {
            return false
        }
    }

    /// Kills a process with SIGTERM
    func killProcess(pid: Int32) async throws {
        guard canKillProcess(pid: pid) else {
            throw ProcessServiceError.permissionDenied
        }

        let result = Darwin.kill(pid, SIGTERM)
        if result != 0 {
            throw ProcessServiceError.killFailed(errno: errno)
        }
    }
}

enum ProcessServiceError: Error, LocalizedError {
    case permissionDenied
    case killFailed(errno: Int32)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Cannot kill process: permission denied"
        case .killFailed(let errno):
            return "Failed to kill process: \(String(cString: strerror(errno)))"
        }
    }
}
