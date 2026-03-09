//
//  PortScannerService.swift
//  Harbor
//

import Foundation

actor PortScannerService {
    /// Checks if a specific port is open using BSD sockets
    func isPortOpen(_ port: Int) async -> Bool {
        let socketFD = socket(AF_INET, SOCK_STREAM, 0)
        guard socketFD >= 0 else { return false }

        defer { close(socketFD) }

        // Set socket timeout
        var timeout = timeval()
        timeout.tv_sec = 0
        timeout.tv_usec = Int32(Constants.portScanTimeout * 1_000_000)
        setsockopt(socketFD, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
        setsockopt(socketFD, SOL_SOCKET, SO_SNDTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))

        // Configure address
        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = in_port_t(port).bigEndian
        addr.sin_addr.s_addr = inet_addr("127.0.0.1")

        // Attempt connection
        let connectResult = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                connect(socketFD, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }

        return connectResult == 0
    }

    /// Scans a range of ports and returns active port information
    func scanPortRange(_ range: ClosedRange<Int>) async -> [PortInfo] {
        await withTaskGroup(of: PortInfo?.self) { group in
            for port in range {
                group.addTask {
                    await self.checkPort(port)
                }
            }

            var results: [PortInfo] = []
            for await portInfo in group {
                if let portInfo = portInfo {
                    results.append(portInfo)
                }
            }
            return results
        }
    }

    /// Checks a single port and gathers metadata if active
    private func checkPort(_ port: Int) async -> PortInfo? {
        guard await isPortOpen(port) else { return nil }

        // Quick HTTP check - verify it's actually an HTTP server
        guard await isHTTPServer(port: port) else { return nil }

        // Get PID for this port
        guard let pid = await getPID(forPort: port) else { return nil }

        // Gather process metadata
        let processName = await getProcessName(pid: pid) ?? "Unknown"
        let workingDirectory = await getWorkingDirectory(pid: pid) ?? "Unknown"
        let command = await getCommand(pid: pid) ?? "Unknown"
        let startTime = await getStartTime(pid: pid) ?? Date()

        return PortInfo(
            port: port,
            pid: Int(pid),
            processName: processName,
            workingDirectory: workingDirectory,
            command: command,
            startTime: startTime
        )
    }

    /// Quick check to verify if a port is serving HTTP
    private func isHTTPServer(port: Int) async -> Bool {
        guard let url = URL(string: "http://localhost:\(port)/") else { return false }

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 0.5 // Fast timeout

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { return false }

            // Only consider it a web server if it returns 2xx or 3xx status codes
            // This filters out services that respond with errors (4xx, 5xx)
            let statusCode = httpResponse.statusCode
            return (200...399).contains(statusCode)
        } catch {
            // Not an HTTP server, or doesn't respond to HTTP
            return false
        }
    }

    // MARK: - Metadata Gathering

    private func getPID(forPort port: Int) async -> Int32? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        // Use -sTCP:LISTEN to only get processes LISTENING on the port (not just connected to it)
        process.arguments = ["-i", ":\(port)", "-sTCP:LISTEN", "-t"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe() // Suppress errors

        do {
            try process.run()
            process.waitUntilExit()

            guard process.terminationStatus == 0 else { return nil }

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)

            if let pidString = output?.split(separator: "\n").first,
               let pid = Int32(pidString) {
                return pid
            }
        } catch {
            return nil
        }

        return nil
    }

    private func getProcessName(pid: Int32) async -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-p", "\(pid)", "-o", "comm="]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()

            guard process.terminationStatus == 0 else { return nil }

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)

            return output?.isEmpty == false ? output : nil
        } catch {
            return nil
        }
    }

    private func getWorkingDirectory(pid: Int32) async -> String? {
        // Try pwdx first (more reliable)
        let pwdxProcess = Process()
        pwdxProcess.executableURL = URL(fileURLWithPath: "/usr/sbin/pwdx")
        pwdxProcess.arguments = ["\(pid)"]

        let pwdxPipe = Pipe()
        pwdxProcess.standardOutput = pwdxPipe
        pwdxProcess.standardError = Pipe()

        do {
            try pwdxProcess.run()
            pwdxProcess.waitUntilExit()

            if pwdxProcess.terminationStatus == 0 {
                let data = pwdxPipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                    // pwdx output format: "PID: /path/to/directory"
                    let components = output.split(separator: ":", maxSplits: 1)
                    if components.count == 2 {
                        return String(components[1]).trimmingCharacters(in: .whitespaces)
                    }
                }
            }
        } catch {
            // Fall through to lsof method
        }

        // Fallback to lsof
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        process.arguments = ["-a", "-p", "\(pid)", "-d", "cwd", "-Fn"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()

            guard process.terminationStatus == 0 else { return nil }

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""

            // Parse lsof -Fn output (format: "n/path/to/directory")
            for line in output.split(separator: "\n") {
                if line.hasPrefix("n") {
                    return String(line.dropFirst())
                }
            }
        } catch {
            return nil
        }

        return nil
    }

    private func getCommand(pid: Int32) async -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-p", "\(pid)", "-o", "args="]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()

            guard process.terminationStatus == 0 else { return nil }

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)

            return output?.isEmpty == false ? output : nil
        } catch {
            return nil
        }
    }

    private func getStartTime(pid: Int32) async -> Date? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-p", "\(pid)", "-o", "lstart="]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()

            guard process.terminationStatus == 0 else { return nil }

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)

            guard let dateString = output else { return nil }

            // Parse format: "Mon Jan  2 15:04:05 2006"
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE MMM d HH:mm:ss yyyy"
            formatter.locale = Locale(identifier: "en_US_POSIX")

            return formatter.date(from: dateString)
        } catch {
            return nil
        }
    }
}
