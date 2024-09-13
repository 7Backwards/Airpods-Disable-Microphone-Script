//
//  BluetoothMicSwitcherApp.swift
//  BluetoothMicSwitcher
//
//  Created by Gonçalo on 12/09/2024.
//

import CoreAudio
import SwiftUI
import AppKit

@main
struct AirPodsMicrophoneSwitcherApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView() // We don't need any settings UI for now
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    let audioDeviceManager = AudioDeviceManager()
    var selectedDeviceID: AudioDeviceID?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the status item only once
        setupMenuBar()
        loadSelectedDevice()
        checkAndSwitchInputDevice()
        let startOnLogin = UserDefaults.standard.bool(forKey: "StartOnLogin")

        // Start a timer to periodically check if AirPods are the current input device
        Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(checkAndSwitchInputDevice), userInfo: nil, repeats: true)
    }
    
    // Create the menu bar item only once
    private func setupMenuBar() {
        // Avoid re-creating the status item if it already exists
        if statusItem == nil {
            statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            
            if let button = statusItem?.button {
                if let appIcon = NSImage(named: "menuBarIcon") {
                    let size = NSSize(width: 28, height: 22)
                    appIcon.size = size
                    
                    button.image = appIcon
                }
                button.action = #selector(showMenu)
            }
        }
        
        // Initially set the menu when the app is launched
        refreshInputDevicesMenu()
    }
    
    // Show the menu when the user clicks the status item
    @objc private func showMenu() {
        refreshInputDevicesMenu()
        statusItem?.menu?.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
    }
    
    // Refresh the input devices menu
    private func refreshInputDevicesMenu() {
        // Create a new menu to update the contents
        let menu = NSMenu()
        
        // Add a header to clarify the purpose
        menu.addItem(NSMenuItem(title: "Select Preferred Input Device", action: nil, keyEquivalent: "").setAsHeader())
        
        // Add a status showing the current input device in use
        if let currentInputDevice = audioDeviceManager.getCurrentInputDevice(), let deviceName = audioDeviceManager.getDeviceName(deviceID: currentInputDevice) {
            let statusItem = NSMenuItem(title: "Currently Using: \(deviceName)", action: nil, keyEquivalent: "")
            statusItem.isEnabled = false
            menu.addItem(statusItem)
        }
        
        // Add a submenu for selecting preferred input devices
        let inputDeviceMenu = NSMenu()
        
        // Get available devices excluding AirPods and only show input devices
        let availableDevices = audioDeviceManager.getAvailableDevices().filter { $0.isInput && !$0.deviceName.contains("AirPods") }
        
        // Add devices to the submenu
        for device in availableDevices {
            let menuItem = NSMenuItem(title: device.deviceName, action: #selector(selectInputDevice(_:)), keyEquivalent: "")
            menuItem.representedObject = device.deviceID
            menuItem.state = (device.deviceID == selectedDeviceID) ? .on : .off
            inputDeviceMenu.addItem(menuItem)
        }
        
        let inputDeviceMenuItem = NSMenuItem(title: "Preferred Input Device", action: nil, keyEquivalent: "")
        menu.setSubmenu(inputDeviceMenu, for: inputDeviceMenuItem)
        menu.addItem(inputDeviceMenuItem)
        
        // Add a quit option
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        
        // Set the updated menu to the status item
        statusItem?.menu = menu
    }
    
    // Select input device from the menu
    @objc func selectInputDevice(_ sender: NSMenuItem) {
        guard var deviceID = sender.representedObject as? AudioDeviceID else { return }
        selectedDeviceID = deviceID
        saveSelectedDevice(deviceID)
        
        // Immediately switch to the selected device if AirPods are already connected
        audioDeviceManager.setDefaultInputDevice(deviceID: &deviceID)
        
        // Refresh the menu to show the updated "Currently Using" status
        refreshInputDevicesMenu()
    }
    
    // Save the selected device to UserDefaults
    private func saveSelectedDevice(_ deviceID: AudioDeviceID) {
        let defaults = UserDefaults.standard
        defaults.set(deviceID, forKey: "selectedInputDeviceID")
    }
    
    // Load the selected device from UserDefaults
    private func loadSelectedDevice() {
        let defaults = UserDefaults.standard
        if let savedDeviceID = defaults.object(forKey: "selectedInputDeviceID") as? AudioDeviceID {
            selectedDeviceID = savedDeviceID
        }
    }
    
    // Check if AirPods are the current input and switch to the selected input device
    @objc private func checkAndSwitchInputDevice() {
        guard let currentInputDeviceID = audioDeviceManager.getCurrentInputDevice() else {
            print("Unable to retrieve current input device")
            return
        }
        
        if audioDeviceManager.isAirPods(deviceID: currentInputDeviceID) {
            print("AirPods detected, switching to the selected input device.")
            
            // If user has selected a device, switch to it
            if var deviceID = selectedDeviceID {
                audioDeviceManager.setDefaultInputDevice(deviceID: &deviceID)
                print("Switched to selected input device: \(deviceID)")
            } else {
                print("No selected input device.")
            }
        }
        
        // Refresh the menu to show the updated "Currently Using" status
        refreshInputDevicesMenu()
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(self)
    }
}

// Helper extension to set a menu item as a header
extension NSMenuItem {
    func setAsHeader() -> NSMenuItem {
        self.isEnabled = false
        self.attributedTitle = NSAttributedString(string: self.title, attributes: [NSAttributedString.Key.font: NSFont.boldSystemFont(ofSize: 12)])
        return self
    }
}
