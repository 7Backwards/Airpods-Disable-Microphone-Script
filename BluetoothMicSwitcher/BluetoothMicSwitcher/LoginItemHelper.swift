//
//  LoginItemHelper.swift
//  BluetoothMicSwitcher
//
//  Created by Gonçalo on 12/09/2024.
//

import Foundation
import ServiceManagement

class LoginItemHelper {
    
    // The identifier of the helper app to start on login
    static let helperBundleIdentifier = "com.yourcompany.yourapp.helper"
    
    static func setLaunchAtLogin(_ enabled: Bool) {
        do {
            let appService = SMAppService.loginItem(identifier: helperBundleIdentifier)
            if enabled {
                try appService.register()
            } else {
                try appService.unregister()
            }
        } catch {
            print("Failed to modify login item: \(error)")
        }
    }
    
    static func isLaunchAtLoginEnabled() -> Bool {
        let appService = SMAppService.loginItem(identifier: helperBundleIdentifier)
        return appService.status == .enabled
    }
}
