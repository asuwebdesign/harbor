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
