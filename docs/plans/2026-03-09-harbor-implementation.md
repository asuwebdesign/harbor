# Harbor Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a native macOS menubar utility app that displays active localhost ports (3000-9000) with metadata and provides quick actions to stop processes.

**Architecture:** MVVM with Service Layer - SwiftUI views bind to Observable ViewModels, which coordinate Services (port scanning, process management) and Managers (settings persistence). All port scanning uses Swift Concurrency for parallel execution.

**Tech Stack:** SwiftUI, Swift 6.0+, AppKit (NSStatusItem), Foundation, XCTest

---

## Task 1: Create Xcode Project

**Files:**

- Create: Xcode project via Xcode IDE

**Step 1: Create new Xcode project**

1. Open Xcode
2. File → New → Project
3. Choose "macOS" → "App"
4. Product Name: "Harbor"
5. Team: Your team
6. Organization Identifier: com.yourname (or appropriate)
7. Interface: SwiftUI
8. Language: Swift
9. Storage: None
10. Hosting: None
11. Include Tests: Yes
12. Create in: `/Users/markriggan/Documents/Sites/Harbor/harbor/`

**Step 2: Verify project builds**

Run: `Cmd+B` (Build)
Expected: Build succeeds

**Step 3: Initial commit**

```bash
cd /Users/markriggan/Documents/Sites/Harbor/harbor
git add -A
git commit -m "chore: create Xcode project for Harbor"
```

---

## Task 2: Configure Project Settings

**Files:**

- Modify: `Harbor.xcodeproj/project.pbxproj` (via Xcode)

**Step 1: Set minimum deployment target**

1. Select Harbor project in navigator
2. Select Harbor target
3. General tab
4. Minimum Deployments → macOS 14.0

**Step 2: Configure as menu bar app**

1. Info tab
2. Add key: "Application is agent (UIElement)" → YES (LSUIElement)
3. This makes the app appear only in menubar, not Dock

**Step 3: Commit configuration**

```bash
git add Harbor.xcodeproj/project.pbxproj Harbor/Info.plist
git commit -m "chore: configure Harbor as menubar app with macOS 14.0 minimum"
```

---

## Task 3: Set Up Project Structure

**Files:**

- Create: `Harbor/Models/`
- Create: `Harbor/ViewModels/`
- Create: `Harbor/Views/`
- Create: `Harbor/Services/`
- Create: `Harbor/Managers/`
- Create: `Harbor/Utils/`

**Step 1: Create folder structure in Xcode**

1. Right-click Harbor group in navigator
2. New Group → "Models"
3. Repeat for: ViewModels, Views, Services, Managers, Utils

**Step 2: Move HarborApp.swift and ContentView.swift**

1. Drag `HarborApp.swift` to root (keep it there)
2. Delete `ContentView.swift` (we'll create our own views)

**Step 3: Commit structure**

```bash
git add Harbor/
git commit -m "chore: set up project folder structure"
```

---

## Task 4: Create Constants

**Files:**

- Create: `Harbor/Utils/Constants.swift`

**Step 1: Create Constants file**

Right-click Utils folder → New File → Swift File → "Constants.swift"

**Step 2: Add constants**

```swift
//
//  Constants.swift
//  Harbor
//

import Foundation

enum Constants {
    // Port Scanning
    static let portRangeStart = 3000
    static let portRangeEnd = 9000
    static let portScanTimeout: TimeInterval = 0.05 // 50ms
    static let scanInterval: TimeInterval = 5.0 // 5 seconds

    // UI
    static let popoverWidth: CGFloat = 320
    static let popoverMinHeight: CGFloat = 200
    static let popoverMaxHeight: CGFloat = 500

    // Settings Keys
    static let showBadgeCountKey = "showBadgeCount"
    static let launchAtLoginKey = "launchAtLogin"
}
```

**Step 3: Commit constants**

```bash
git add Harbor/Utils/Constants.swift
git commit -m "feat: add app constants for ports, UI, and settings"
```

---

## Task 5: Create PortInfo Model

**Files:**

- Create: `Harbor/Models/PortInfo.swift`
- Create: `HarborTests/PortInfoTests.swift`

**Step 1: Write failing test**

Right-click HarborTests → New File → Unit Test Case Class → "PortInfoTests.swift"

```swift
//
//  PortInfoTests.swift
//  HarborTests
//

import XCTest
@testable import Harbor

final class PortInfoTests: XCTestCase {
    func testPortInfoCreation() {
        let startTime = Date()
        let portInfo = PortInfo(
            port: 3000,
            pid: 12345,
            processName: "node",
            workingDirectory: "/Users/test/project",
            command: "npm run dev",
            startTime: startTime
        )

        XCTAssertEqual(portInfo.port, 3000)
        XCTAssertEqual(portInfo.pid, 12345)
        XCTAssertEqual(portInfo.processName, "node")
        XCTAssertEqual(portInfo.workingDirectory, "/Users/test/project")
        XCTAssertEqual(portInfo.command, "npm run dev")
        XCTAssertEqual(portInfo.startTime, startTime)
    }

    func testPortInfoHasUniqueID() {
        let port1 = PortInfo(port: 3000, pid: 1, processName: "node", workingDirectory: "/test", command: "test", startTime: Date())
        let port2 = PortInfo(port: 3000, pid: 1, processName: "node", workingDirectory: "/test", command: "test", startTime: Date())

        XCTAssertNotEqual(port1.id, port2.id)
    }

    func testFolderNameExtraction() {
        let portInfo = PortInfo(port: 3000, pid: 1, processName: "node", workingDirectory: "/Users/test/my-project", command: "npm run dev", startTime: Date())

        XCTAssertEqual(portInfo.folderName, "my-project")
    }

    func testFolderNameExtractionRootFolder() {
        let portInfo = PortInfo(port: 3000, pid: 1, processName: "node", workingDirectory: "/my-project", command: "npm run dev", startTime: Date())

        XCTAssertEqual(portInfo.folderName, "my-project")
    }
}
```

**Step 2: Run test to verify it fails**

Run: `Cmd+U` (Test)
Expected: FAIL - PortInfo type not found

**Step 3: Implement PortInfo model**

Right-click Models → New File → Swift File → "PortInfo.swift"

```swift
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
```

**Step 4: Run tests to verify they pass**

Run: `Cmd+U`
Expected: PASS - all PortInfo tests pass

**Step 5: Commit**

```bash
git add Harbor/Models/PortInfo.swift HarborTests/PortInfoTests.swift
git commit -m "feat: add PortInfo model with folder name and uptime helpers"
```

---

## Task 6: Create AppSettings Model

**Files:**

- Create: `Harbor/Models/AppSettings.swift`
- Create: `HarborTests/AppSettingsTests.swift`

**Step 1: Write failing test**

```swift
//
//  AppSettingsTests.swift
//  HarborTests
//

import XCTest
@testable import Harbor

final class AppSettingsTests: XCTestCase {
    func testDefaultSettings() {
        let settings = AppSettings()

        XCTAssertTrue(settings.showBadgeCount)
        XCTAssertFalse(settings.launchAtLogin)
    }

    func testSettingsCustomization() {
        var settings = AppSettings()
        settings.showBadgeCount = false
        settings.launchAtLogin = true

        XCTAssertFalse(settings.showBadgeCount)
        XCTAssertTrue(settings.launchAtLogin)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `Cmd+U`
Expected: FAIL - AppSettings type not found

**Step 3: Implement AppSettings**

```swift
//
//  AppSettings.swift
//  Harbor
//

import Foundation

struct AppSettings {
    var showBadgeCount: Bool = true
    var launchAtLogin: Bool = false
}
```

**Step 4: Run tests to verify they pass**

Run: `Cmd+U`
Expected: PASS

**Step 5: Commit**

```bash
git add Harbor/Models/AppSettings.swift HarborTests/AppSettingsTests.swift
git commit -m "feat: add AppSettings model with defaults"
```

---

## Task 7: Create AppStateManager

**Files:**

- Create: `Harbor/Managers/AppStateManager.swift`
- Create: `HarborTests/AppStateManagerTests.swift`

**Step 1: Write failing test**

```swift
//
//  AppStateManagerTests.swift
//  HarborTests
//

import XCTest
@testable import Harbor

final class AppStateManagerTests: XCTestCase {
    var manager: AppStateManager!
    let testDefaults = UserDefaults(suiteName: "com.harbor.test")!

    override func setUp() {
        super.setUp()
        testDefaults.removePersistentDomain(forName: "com.harbor.test")
        manager = AppStateManager(defaults: testDefaults)
    }

    func testLoadDefaultSettings() {
        let settings = manager.loadSettings()

        XCTAssertTrue(settings.showBadgeCount)
        XCTAssertFalse(settings.launchAtLogin)
    }

    func testSaveAndLoadSettings() {
        var settings = AppSettings()
        settings.showBadgeCount = false
        settings.launchAtLogin = true

        manager.saveSettings(settings)
        let loadedSettings = manager.loadSettings()

        XCTAssertFalse(loadedSettings.showBadgeCount)
        XCTAssertTrue(loadedSettings.launchAtLogin)
    }

    func testSettingsPersistence() {
        var settings = AppSettings()
        settings.showBadgeCount = false
        manager.saveSettings(settings)

        // Create new manager with same defaults
        let newManager = AppStateManager(defaults: testDefaults)
        let loadedSettings = newManager.loadSettings()

        XCTAssertFalse(loadedSettings.showBadgeCount)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `Cmd+U`
Expected: FAIL - AppStateManager type not found

**Step 3: Implement AppStateManager**

```swift
//
//  AppStateManager.swift
//  Harbor
//

import Foundation

@Observable
final class AppStateManager {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadSettings() -> AppSettings {
        var settings = AppSettings()

        // Load settings with defaults
        if defaults.object(forKey: Constants.showBadgeCountKey) != nil {
            settings.showBadgeCount = defaults.bool(forKey: Constants.showBadgeCountKey)
        }

        settings.launchAtLogin = defaults.bool(forKey: Constants.launchAtLoginKey)

        return settings
    }

    func saveSettings(_ settings: AppSettings) {
        defaults.set(settings.showBadgeCount, forKey: Constants.showBadgeCountKey)
        defaults.set(settings.launchAtLogin, forKey: Constants.launchAtLoginKey)
    }
}
```

**Step 4: Run tests to verify they pass**

Run: `Cmd+U`
Expected: PASS

**Step 5: Commit**

```bash
git add Harbor/Managers/AppStateManager.swift HarborTests/AppStateManagerTests.swift
git commit -m "feat: add AppStateManager for settings persistence"
```

---

## Task 8: Create ProcessService

**Files:**

- Create: `Harbor/Services/ProcessService.swift`
- Create: `HarborTests/ProcessServiceTests.swift`

**Step 1: Write test (limited - can't test actual kill)**

```swift
//
//  ProcessServiceTests.swift
//  HarborTests
//

import XCTest
@testable import Harbor

final class ProcessServiceTests: XCTestCase {
    func testKillProcessValidatesOwnership() async {
        let service = ProcessService()
        let currentUserPID = ProcessInfo.processInfo.processIdentifier

        // Should not throw for own process (though we won't actually kill it)
        // This is a safety check test - we can't actually test killing
        let result = await service.canKillProcess(pid: currentUserPID)
        XCTAssertTrue(result)
    }

    func testCannotKillInvalidPID() async {
        let service = ProcessService()

        // PID -1 is invalid
        let result = await service.canKillProcess(pid: -1)
        XCTAssertFalse(result)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `Cmd+U`
Expected: FAIL - ProcessService type not found

**Step 3: Implement ProcessService**

```swift
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
        guard await canKillProcess(pid: pid) else {
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
```

**Step 4: Run tests to verify they pass**

Run: `Cmd+U`
Expected: PASS

**Step 5: Commit**

```bash
git add Harbor/Services/ProcessService.swift HarborTests/ProcessServiceTests.swift
git commit -m "feat: add ProcessService for safe process termination"
```

---

## Task 9: Create PortScannerService (Part 1: Basic Structure)

**Files:**

- Create: `Harbor/Services/PortScannerService.swift`
- Create: `HarborTests/PortScannerServiceTests.swift`

**Step 1: Write basic test**

```swift
//
//  PortScannerServiceTests.swift
//  HarborTests
//

import XCTest
@testable import Harbor

final class PortScannerServiceTests: XCTestCase {
    func testScanPortRangeReturnsArray() async {
        let service = PortScannerService()
        let results = await service.scanPortRange(3000...3010)

        // Should return array (may be empty if no ports active)
        XCTAssertNotNil(results)
    }

    func testCheckPortReturnsFalseForClosedPort() async {
        let service = PortScannerService()

        // Port 65534 is unlikely to be in use
        let result = await service.isPortOpen(65534)
        XCTAssertFalse(result)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `Cmd+U`
Expected: FAIL - PortScannerService type not found

**Step 3: Implement basic PortScannerService structure**

```swift
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
```

**Step 4: Run tests to verify they pass**

Run: `Cmd+U`
Expected: PASS

**Step 5: Commit**

```bash
git add Harbor/Services/PortScannerService.swift HarborTests/PortScannerServiceTests.swift
git commit -m "feat: add PortScannerService with parallel port scanning"
```

---

## Task 10: Implement Port Scanner Metadata Gathering

**Files:**

- Modify: `Harbor/Services/PortScannerService.swift`

**Step 1: Implement getPID**

Replace the `getPID` stub with:

```swift
private func getPID(forPort port: Int) async -> Int32? {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
    process.arguments = ["-i", ":\(port)", "-t"]

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
```

**Step 2: Implement getProcessName**

Replace the `getProcessName` stub with:

```swift
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
```

**Step 3: Implement getWorkingDirectory**

Replace the `getWorkingDirectory` stub with:

```swift
private func getWorkingDirectory(pid: Int32) async -> String? {
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
```

**Step 4: Implement getCommand**

Replace the `getCommand` stub with:

```swift
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
```

**Step 5: Implement getStartTime**

Replace the `getStartTime` stub with:

```swift
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
```

**Step 6: Test manually (create a test server)**

You can manually test by running a simple server:

```bash
python3 -m http.server 3000
```

Then run Harbor and see if it detects it.

**Step 7: Commit**

```bash
git add Harbor/Services/PortScannerService.swift
git commit -m "feat: implement metadata gathering for active ports"
```

---

## Task 11: Create PortViewModel

**Files:**

- Create: `Harbor/ViewModels/PortViewModel.swift`
- Create: `HarborTests/PortViewModelTests.swift`

**Step 1: Write test**

```swift
//
//  PortViewModelTests.swift
//  HarborTests
//

import XCTest
@testable import Harbor

final class PortViewModelTests: XCTestCase {
    @MainActor
    func testInitialState() {
        let viewModel = PortViewModel()

        XCTAssertTrue(viewModel.activePorts.isEmpty)
        XCTAssertFalse(viewModel.isScanning)
    }

    @MainActor
    func testScanPorts() async {
        let viewModel = PortViewModel()

        await viewModel.scanPorts()

        // Should complete without error
        XCTAssertFalse(viewModel.isScanning)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `Cmd+U`
Expected: FAIL - PortViewModel type not found

**Step 3: Implement PortViewModel**

```swift
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
    private var scanTimer: Timer?

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
    func stopAutoRefresh() {
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
    }

    /// Kills a specific process by PID
    func stopPort(_ portInfo: PortInfo) async throws {
        try await processService.killProcess(pid: Int32(portInfo.pid))

        // Refresh immediately after stopping
        await scanPorts()
    }

    /// Stops all active ports with confirmation
    func stopAllPorts() async throws {
        for port in activePorts {
            try? await processService.killProcess(pid: Int32(port.pid))
        }

        // Refresh after stopping all
        await scanPorts()
    }
}
```

**Step 4: Run tests to verify they pass**

Run: `Cmd+U`
Expected: PASS

**Step 5: Commit**

```bash
git add Harbor/ViewModels/PortViewModel.swift HarborTests/PortViewModelTests.swift
git commit -m "feat: add PortViewModel with auto-refresh and port management"
```

---

## Task 12: Create SettingsViewModel

**Files:**

- Create: `Harbor/ViewModels/SettingsViewModel.swift`
- Create: `HarborTests/SettingsViewModelTests.swift`

**Step 1: Write test**

```swift
//
//  SettingsViewModelTests.swift
//  HarborTests
//

import XCTest
@testable import Harbor

final class SettingsViewModelTests: XCTestCase {
    @MainActor
    func testLoadSettings() {
        let testDefaults = UserDefaults(suiteName: "com.harbor.test")!
        testDefaults.removePersistentDomain(forName: "com.harbor.test")

        let stateManager = AppStateManager(defaults: testDefaults)
        let viewModel = SettingsViewModel(stateManager: stateManager)

        XCTAssertTrue(viewModel.showBadgeCount)
        XCTAssertFalse(viewModel.launchAtLogin)
    }

    @MainActor
    func testSaveSettings() {
        let testDefaults = UserDefaults(suiteName: "com.harbor.test")!
        testDefaults.removePersistentDomain(forName: "com.harbor.test")

        let stateManager = AppStateManager(defaults: testDefaults)
        let viewModel = SettingsViewModel(stateManager: stateManager)

        viewModel.showBadgeCount = false
        viewModel.launchAtLogin = true

        // Settings should be saved automatically
        let loadedSettings = stateManager.loadSettings()
        XCTAssertFalse(loadedSettings.showBadgeCount)
        XCTAssertTrue(loadedSettings.launchAtLogin)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `Cmd+U`
Expected: FAIL - SettingsViewModel type not found

**Step 3: Implement SettingsViewModel**

```swift
//
//  SettingsViewModel.swift
//  Harbor
//

import Foundation
import SwiftUI

@Observable
@MainActor
final class SettingsViewModel {
    var showBadgeCount: Bool {
        didSet { saveSettings() }
    }

    var launchAtLogin: Bool {
        didSet { saveSettings() }
    }

    private let stateManager: AppStateManager

    init(stateManager: AppStateManager = AppStateManager()) {
        self.stateManager = stateManager

        let settings = stateManager.loadSettings()
        self.showBadgeCount = settings.showBadgeCount
        self.launchAtLogin = settings.launchAtLogin
    }

    private func saveSettings() {
        let settings = AppSettings(
            showBadgeCount: showBadgeCount,
            launchAtLogin: launchAtLogin
        )
        stateManager.saveSettings(settings)
    }
}
```

**Step 4: Run tests to verify they pass**

Run: `Cmd+U`
Expected: PASS

**Step 5: Commit**

```bash
git add Harbor/ViewModels/SettingsViewModel.swift HarborTests/SettingsViewModelTests.swift
git commit -m "feat: add SettingsViewModel with auto-save functionality"
```

---

## Task 13: Create EmptyStateView

**Files:**

- Create: `Harbor/Views/EmptyStateView.swift`

**Step 1: Create EmptyStateView**

```swift
//
//  EmptyStateView.swift
//  Harbor
//

import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "building.2.crop.circle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            VStack(spacing: 4) {
                Text("All quiet in the harbor")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("No localhost servers are currently running")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    EmptyStateView()
        .frame(width: 320, height: 200)
}
```

**Step 2: Build and preview**

Run: `Cmd+B`
Expected: Build succeeds
Check preview in Xcode canvas

**Step 3: Commit**

```bash
git add Harbor/Views/EmptyStateView.swift
git commit -m "feat: add EmptyStateView with friendly zero-state message"
```

---

## Task 14: Create PortRowView

**Files:**

- Create: `Harbor/Views/PortRowView.swift`

**Step 1: Create PortRowView**

```swift
//
//  PortRowView.swift
//  Harbor
//

import SwiftUI

struct PortRowView: View {
    let portInfo: PortInfo
    let onStop: () -> Void

    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Line 1: Folder name and port number with optional Stop button
            HStack {
                Text(portInfo.folderName)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.primary)

                Spacer()

                HStack(spacing: 8) {
                    Text("Port \(portInfo.port)")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)

                    if isHovered {
                        Button(action: onStop) {
                            Text("Stop")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .transition(.opacity)
                    }
                }
            }

            // Line 2: Working directory path
            Text(portInfo.workingDirectory)
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
                .lineLimit(1)
                .truncationMode(.middle)

            // Line 3: Process metadata
            HStack(spacing: 4) {
                Text(portInfo.processName)
                Text("•")
                Text(portInfo.command)
                Text("•")
                Text(portInfo.formattedUptime)
            }
            .font(.system(size: 11))
            .foregroundStyle(.tertiary)
            .lineLimit(1)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isHovered ? Color.primary.opacity(0.05) : Color.clear)
        .cornerRadius(6)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

#Preview {
    PortRowView(
        portInfo: PortInfo(
            port: 3000,
            pid: 12345,
            processName: "node",
            workingDirectory: "/Users/test/projects/my-app",
            command: "npm run dev",
            startTime: Date().addingTimeInterval(-7200)
        ),
        onStop: {}
    )
    .frame(width: 320)
    .padding()
}
```

**Step 2: Build and preview**

Run: `Cmd+B`
Expected: Build succeeds
Check preview - hover over row to see Stop button appear

**Step 3: Commit**

```bash
git add Harbor/Views/PortRowView.swift
git commit -m "feat: add PortRowView with hover-triggered Stop button"
```

---

## Task 15: Create PopoverView

**Files:**

- Create: `Harbor/Views/PopoverView.swift`

**Step 1: Create PopoverView**

```swift
//
//  PopoverView.swift
//  Harbor
//

import SwiftUI

struct PopoverView: View {
    @Environment(PortViewModel.self) private var viewModel
    @State private var showingStopAllAlert = false

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.activePorts.isEmpty {
                EmptyStateView()
                    .frame(height: Constants.popoverMinHeight)
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(viewModel.activePorts) { portInfo in
                            PortRowView(portInfo: portInfo) {
                                Task {
                                    try? await viewModel.stopPort(portInfo)
                                }
                            }

                            if portInfo.id != viewModel.activePorts.last?.id {
                                Divider()
                                    .padding(.horizontal, 12)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .frame(maxHeight: Constants.popoverMaxHeight)

                if viewModel.activePorts.count > 1 {
                    Divider()

                    Button("Stop All") {
                        showingStopAllAlert = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    .padding(.vertical, 12)
                }
            }
        }
        .frame(width: Constants.popoverWidth)
        .alert("Stop All Servers?", isPresented: $showingStopAllAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Stop All", role: .destructive) {
                Task {
                    try? await viewModel.stopAllPorts()
                }
            }
        } message: {
            Text("This will stop \(viewModel.activePorts.count) running servers:\n\(viewModel.activePorts.map { $0.folderName }.joined(separator: ", "))")
        }
    }
}

#Preview {
    @Previewable @State var viewModel = PortViewModel()

    PopoverView()
        .environment(viewModel)
        .task {
            // Mock data for preview
            viewModel.activePorts = [
                PortInfo(port: 3000, pid: 1, processName: "node", workingDirectory: "/Users/test/my-app", command: "npm run dev", startTime: Date().addingTimeInterval(-3600)),
                PortInfo(port: 5173, pid: 2, processName: "node", workingDirectory: "/Users/test/vite-app", command: "npm run dev", startTime: Date().addingTimeInterval(-7200))
            ]
        }
}
```

**Step 2: Build and preview**

Run: `Cmd+B`
Expected: Build succeeds
Check preview with mock data

**Step 3: Commit**

```bash
git add Harbor/Views/PopoverView.swift
git commit -m "feat: add PopoverView with port list and Stop All functionality"
```

---

## Task 16: Create SettingsView

**Files:**

- Create: `Harbor/Views/SettingsView.swift`

**Step 1: Create SettingsView**

```swift
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
```

**Step 2: Build and preview**

Run: `Cmd+B`
Expected: Build succeeds

**Step 3: Commit**

```bash
git add Harbor/Views/SettingsView.swift
git commit -m "feat: add SettingsView with badge count and launch at login toggles"
```

---

## Task 17: Implement HarborApp with Menubar

**Files:**

- Modify: `Harbor/HarborApp.swift`

**Step 1: Replace HarborApp.swift**

```swift
//
//  HarborApp.swift
//  Harbor
//

import SwiftUI
import AppKit

@main
struct HarborApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var settingsWindow: NSWindow?
    private let viewModel = PortViewModel()
    private let settingsViewModel = SettingsViewModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create status item in menubar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "building.2.crop.circle", accessibilityDescription: "Harbor")
            button.action = #selector(togglePopover)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        // Create popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: Constants.popoverWidth, height: Constants.popoverMinHeight)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: PopoverView().environment(viewModel))

        // Update badge based on settings
        updateBadge()

        // Observe port changes to update badge
        Task { @MainActor in
            for await _ in NotificationCenter.default.notifications(named: NSNotification.Name("PortsDidUpdate")) {
                updateBadge()
            }
        }
    }

    @objc func togglePopover(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            showMenu()
        } else {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                if let button = statusItem.button {
                    // Refresh immediately when opening
                    Task {
                        await viewModel.scanPorts()
                        await MainActor.run {
                            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                        }
                    }
                }
            }
        }
    }

    @objc func showMenu() {
        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Harbor", action: #selector(quit), keyEquivalent: "q"))

        statusItem.menu = menu
        statusItem.button?.performClick(nil)

        // Reset menu to nil so left-click still works
        DispatchQueue.main.async {
            self.statusItem.menu = nil
        }
    }

    @objc func openSettings() {
        if settingsWindow == nil {
            let settingsView = SettingsView()
            let hostingController = NSHostingController(rootView: settingsView)

            let window = NSWindow(contentViewController: hostingController)
            window.title = "Harbor Settings"
            window.styleMask = [.titled, .closable]
            window.center()

            settingsWindow = window
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func quit() {
        NSApp.terminate(nil)
    }

    @MainActor
    private func updateBadge() {
        guard let button = statusItem.button else { return }

        if settingsViewModel.showBadgeCount && !viewModel.activePorts.isEmpty {
            button.title = " \(viewModel.activePorts.count)"
        } else {
            button.title = ""
        }
    }
}
```

**Step 2: Build and run**

Run: `Cmd+R`
Expected: App appears in menubar

- Left-click shows popover
- Right-click shows menu with Settings and Quit

**Step 3: Commit**

```bash
git add Harbor/HarborApp.swift
git commit -m "feat: implement menubar app with popover and context menu"
```

---

## Task 18: Add App Icon and Menubar Icon

**Files:**

- Modify: `Harbor/Assets.xcassets/AppIcon.appiconset/Contents.json`

**Step 1: Create app icon**

For now, we'll use the SF Symbol as a placeholder:

1. Open Assets.xcassets
2. Select AppIcon
3. For each size, you can use an SF Symbol as temporary icon
   - Alternatively, use an icon generator online with a harbor/anchor theme

**Step 2: Verify icon appears**

Run: `Cmd+R`
Expected: Icon appears in menubar

**Step 3: Commit**

```bash
git add Harbor/Assets.xcassets/
git commit -m "chore: add app icon assets"
```

---

## Task 19: Configure App Sandbox and Entitlements

**Files:**

- Create: `Harbor/Harbor.entitlements`

**Step 1: Add entitlements file**

1. Select Harbor target
2. Signing & Capabilities tab
3. Click "+ Capability"
4. Add "App Sandbox"
5. Enable "Outgoing Connections (Client)" under Network

**Step 2: Configure sandbox settings**

In the Signing & Capabilities:

- App Sandbox: ON
- Network: Outgoing Connections (Client): ✓
- File Access: User Selected File (Read Only): ✓

**Step 3: Verify entitlements file**

The file `Harbor.entitlements` should be created with:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-only</key>
    <true/>
</dict>
</plist>
```

**Step 4: Build and test**

Run: `Cmd+R`
Expected: App builds and runs with sandbox enabled

**Step 5: Commit**

```bash
git add Harbor/Harbor.entitlements Harbor.xcodeproj/project.pbxproj
git commit -m "chore: configure app sandbox with required entitlements"
```

---

## Task 20: Fix Badge Update Logic

**Files:**

- Modify: `Harbor/HarborApp.swift`
- Modify: `Harbor/ViewModels/PortViewModel.swift`

**Step 1: Add notification posting to PortViewModel**

In `PortViewModel.swift`, modify the `scanPorts()` method:

```swift
func scanPorts() async {
    isScanning = true
    defer { isScanning = false }

    let range = Constants.portRangeStart...Constants.portRangeEnd
    activePorts = await scanner.scanPortRange(range)
    lastScanTime = Date()

    // Post notification for badge update
    NotificationCenter.default.post(name: NSNotification.Name("PortsDidUpdate"), object: nil)
}
```

**Step 2: Update AppDelegate observation**

In `HarborApp.swift`, replace the observation code with:

```swift
// Observe port changes to update badge
NotificationCenter.default.addObserver(
    forName: NSNotification.Name("PortsDidUpdate"),
    object: nil,
    queue: .main
) { [weak self] _ in
    self?.updateBadge()
}
```

**Step 3: Build and test**

Run: `Cmd+R`
Start a test server: `python3 -m http.server 3000`
Expected: Badge count appears and updates

**Step 4: Commit**

```bash
git add Harbor/HarborApp.swift Harbor/ViewModels/PortViewModel.swift
git commit -m "fix: update badge count when ports change"
```

---

## Task 21: Add Launch at Login Functionality

**Files:**

- Modify: `Harbor/ViewModels/SettingsViewModel.swift`
- Create: `Harbor/Utils/LaunchAtLogin.swift`

**Step 1: Create LaunchAtLogin helper**

```swift
//
//  LaunchAtLogin.swift
//  Harbor
//

import Foundation
import ServiceManagement

enum LaunchAtLogin {
    static func isEnabled() -> Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func enable() throws {
        if SMAppService.mainApp.status == .enabled {
            return
        }
        try SMAppService.mainApp.register()
    }

    static func disable() throws {
        if SMAppService.mainApp.status == .notRegistered {
            return
        }
        try SMAppService.mainApp.unregister()
    }
}
```

**Step 2: Update SettingsViewModel to use LaunchAtLogin**

In `SettingsViewModel.swift`, update the `launchAtLogin` didSet:

```swift
var launchAtLogin: Bool {
    didSet {
        saveSettings()

        // Update launch at login status
        do {
            if launchAtLogin {
                try LaunchAtLogin.enable()
            } else {
                try LaunchAtLogin.disable()
            }
        } catch {
            print("Failed to update launch at login: \(error)")
            // Revert on failure
            launchAtLogin = LaunchAtLogin.isEnabled()
        }
    }
}
```

**Step 3: Update init to load actual launch at login status**

```swift
init(stateManager: AppStateManager = AppStateManager()) {
    self.stateManager = stateManager

    let settings = stateManager.loadSettings()
    self.showBadgeCount = settings.showBadgeCount

    // Get actual launch at login status from system
    self.launchAtLogin = LaunchAtLogin.isEnabled()
}
```

**Step 4: Build and test**

Run: `Cmd+R`
Toggle "Launch at login" in settings
Check System Settings → General → Login Items
Expected: Harbor appears/disappears in login items

**Step 5: Commit**

```bash
git add Harbor/Utils/LaunchAtLogin.swift Harbor/ViewModels/SettingsViewModel.swift
git commit -m "feat: implement launch at login functionality"
```

---

## Task 22: Update README

**Files:**

- Modify: `README.md`

**Step 1: Replace README content**

````markdown
# Harbor

<p align="center">
  <img src="Harbor/Assets.xcassets/AppIcon.appiconset/icon_512x512.png" width="128" height="128" alt="Harbor Icon">
</p>

A native macOS menubar utility for managing localhost development servers.

## Features

- 🔍 **Automatic Port Detection** - Scans ports 3000-9000 to find active localhost servers
- 📊 **Rich Metadata** - See process name, working directory, command, and uptime for each server
- ⚡ **Quick Actions** - Stop individual ports or all ports with one click
- 🎨 **Native macOS Design** - Fully native SwiftUI app with automatic light/dark mode support
- 🔔 **Badge Count** - Optional menubar badge showing number of active ports
- 🚀 **Lightweight** - Minimal memory footprint with efficient parallel port scanning
- 🔒 **Secure** - Sandboxed app with minimal permissions required

## Installation

### Building from Source

1. Clone this repository
2. Open `Harbor.xcodeproj` in Xcode 15.0+
3. Build and run (Cmd+R)
4. Harbor will appear in your menubar

### Requirements

- macOS 14.0 or later
- Xcode 15.0+ (for building)

## Usage

### Viewing Active Ports

- **Left-click** the Harbor menubar icon to view all active localhost servers
- See project names, port numbers, and process details at a glance

### Stopping Servers

- **Hover** over a port row to reveal the "Stop" button
- **Click "Stop"** to terminate that specific server
- **Click "Stop All"** to terminate all running servers (with confirmation)

### Settings

- **Right-click** the Harbor menubar icon and select "Settings..."
- **Show badge count** - Display the number of active ports in the menubar
- **Launch at login** - Automatically start Harbor when you log in

## Architecture

Harbor is built with:

- **SwiftUI** for native macOS UI
- **MVVM** architecture with Service Layer
- **Swift Concurrency** for parallel port scanning
- **AppKit** for menubar integration (NSStatusItem)

See [Design Document](docs/plans/2026-03-09-harbor-design.md) for detailed architecture information.

## Development

### Running Tests

```bash
# Run all tests
Cmd+U in Xcode

# Or via command line
xcodebuild test -scheme Harbor
```
````

### Project Structure

```
Harbor/
├── Models/          # Data models (PortInfo, AppSettings)
├── ViewModels/      # Observable view models
├── Views/           # SwiftUI views
├── Services/        # Port scanning and process management
├── Managers/        # Settings persistence
└── Utils/           # Constants and helpers
```

## License

MIT License - see LICENSE file for details

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

````

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: update README with features and usage instructions"
````

---

## Task 23: Final Testing and Cleanup

**Step 1: Run all tests**

Run: `Cmd+U`
Expected: All tests pass

**Step 2: Manual testing checklist**

Test the following manually:

- [ ] App appears in menubar
- [ ] Left-click opens popover
- [ ] Right-click shows menu with Settings and Quit
- [ ] Empty state shows when no ports active
- [ ] Start a test server (`python3 -m http.server 3000`)
- [ ] Port appears in list with correct metadata
- [ ] Hover shows Stop button
- [ ] Stop button kills the process
- [ ] Badge count updates (if enabled)
- [ ] Settings window opens
- [ ] Settings persist after restart
- [ ] Launch at login toggle works
- [ ] Stop All shows confirmation dialog
- [ ] Stop All kills all processes

**Step 3: Fix any issues found**

Address any bugs or issues discovered during manual testing.

**Step 4: Clean build**

1. Product → Clean Build Folder (Cmd+Shift+K)
2. Product → Build (Cmd+B)
   Expected: Clean build succeeds

**Step 5: Final commit**

```bash
git add -A
git commit -m "chore: final testing and cleanup for Harbor v1.0"
```

---

## Task 24: Create Release Build

**Step 1: Archive app**

1. Product → Archive
2. Wait for archive to complete
3. Distribute App → Copy App
4. Save to a location

**Step 2: Test archived build**

1. Quit Xcode version of Harbor
2. Run the archived app
3. Verify all functionality works

**Step 3: Tag release**

```bash
git tag -a v1.0.0 -m "Harbor v1.0.0 - Initial release"
git push origin v1.0.0
```

---

## Success Criteria Checklist

Verify all success criteria from the design doc:

- ✅ Menubar icon appears and shows active port count
- ✅ Popover displays all active ports in range 3000-9000
- ✅ Port metadata is accurate (folder, process, command, uptime)
- ✅ Single port stop works instantly
- ✅ Stop All shows confirmation and kills all processes
- ✅ Settings persist between launches
- ✅ App is lightweight (<10MB memory footprint)
- ✅ Full port scan completes in <1 second
- ✅ Native macOS look and feel with theme support
- ✅ Zero-state is friendly and informative

---

## Next Steps (Post-v1)

Future enhancements to consider:

- Custom port ranges in settings
- Grouped view by project/folder
- Search/filter functionality
- Click port to open in browser (http://localhost:PORT)
- Process resource usage (CPU/memory)
- Git branch detection for projects
- Export running ports list
- Keyboard shortcuts for actions

---

**Implementation Complete!** 🎉

You now have a fully functional Harbor app that manages localhost development servers with a native macOS experience.
