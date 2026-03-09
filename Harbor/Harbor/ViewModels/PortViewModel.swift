//
//  PortViewModel.swift
//  Harbor
//

import Foundation
import SwiftUI

@Observable
@MainActor
final class PortViewModel {
    var activePorts: [PortInfo] = []
    var isScanning = false
    var lastScanTime: Date?

    private let scanner = PortScannerService()
    private let processService = ProcessService()
    nonisolated private var scanTimer: Timer?

    init() {
        startAutoRefresh()
    }

    deinit {
        stopAutoRefresh()
    }

    /// Starts automatic port scanning every 5 seconds
    func startAutoRefresh() {
        scanTimer?.invalidate()
        scanTimer = Timer.scheduledTimer(withTimeInterval: Constants.scanInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.scanPorts()
            }
        }

        // Initial scan
        Task {
            await scanPorts()
        }
    }

    /// Stops automatic port scanning
    nonisolated func stopAutoRefresh() {
        scanTimer?.invalidate()
        scanTimer = nil
    }

    /// Manually scan ports in the configured range
    func scanPorts() async {
        isScanning = true
        defer { isScanning = false }

        let range = Constants.portRangeStart...Constants.portRangeEnd
        activePorts = await scanner.scanPortRange(range)
        lastScanTime = Date()

        // Post notification for badge update
        NotificationCenter.default.post(name: NSNotification.Name("PortsDidUpdate"), object: nil)
    }

    /// Kills a specific process by PID
    func stopPort(_ portInfo: PortInfo) async throws {
        try await processService.killProcess(pid: Int32(portInfo.pid))

        // Refresh immediately after stopping
        await scanPorts()
    }

    /// Stops all active ports with confirmation
    func stopAllPorts() async {
        for port in activePorts {
            try? await processService.killProcess(pid: Int32(port.pid))
        }

        // Refresh after stopping all
        await scanPorts()
    }
}
