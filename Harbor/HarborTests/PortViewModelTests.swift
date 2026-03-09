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
