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
