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
