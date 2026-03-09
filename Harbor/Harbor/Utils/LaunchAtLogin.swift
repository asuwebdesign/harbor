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
