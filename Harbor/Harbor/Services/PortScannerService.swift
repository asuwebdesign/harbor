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

    // MARK: - Metadata Gathering (stubs for now)

    private func getPID(forPort port: Int) async -> Int32? {
        // TODO: Implement in next task
        return nil
    }

    private func getProcessName(pid: Int32) async -> String? {
        // TODO: Implement in next task
        return nil
    }

    private func getWorkingDirectory(pid: Int32) async -> String? {
        // TODO: Implement in next task
        return nil
    }

    private func getCommand(pid: Int32) async -> String? {
        // TODO: Implement in next task
        return nil
    }

    private func getStartTime(pid: Int32) async -> Date? {
        // TODO: Implement in next task
        return nil
    }
}
