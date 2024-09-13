import CoreAudio
import Foundation

class AudioDeviceManager {
    
    // Retrieve all audio devices and print both input and output device names
    func getAvailableDevices() -> [(deviceID: AudioDeviceID, deviceName: String, isInput: Bool)] {
        var devices = [(deviceID: AudioDeviceID, deviceName: String, isInput: Bool)]()
        var deviceCount: UInt32 = 0
        var propertySize = UInt32(MemoryLayout<UInt32>.size)

        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        // Get the number of audio devices
        let status = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize
        )

        if status != noErr {
            print("Error retrieving audio device count: \(status)")
            return []
        }

        deviceCount = propertySize / UInt32(MemoryLayout<AudioDeviceID>.size)
        var deviceList = [AudioDeviceID](repeating: 0, count: Int(deviceCount))

        // Get the list of audio devices
        let statusList = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &deviceList
        )

        if statusList != noErr {
            print("Error retrieving audio devices: \(statusList)")
            return []
        }

        // For each device, retrieve its name and determine if it's an input or output device
        for device in deviceList {
            let deviceName = getDeviceName(deviceID: device) ?? "Unknown"
            let isInput = isInputDevice(deviceID: device)
            devices.append((deviceID: device, deviceName: deviceName, isInput: isInput))

            // Print the device name and whether it is an input or output device
            print("\(deviceName) (ID: \(device)) - Input: \(isInput)")
        }

        return devices
    }

    // Helper function to retrieve device name
    func getDeviceName(deviceID: AudioDeviceID) -> String? {
        var deviceName: CFString = "" as CFString
        var propertySize = UInt32(MemoryLayout<CFString>.size)
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &deviceName
        )

        if status != noErr {
            print("Error retrieving device name for device \(deviceID): \(status)")
            return nil
        }

        return deviceName as String
    }

    // Check if a device is an input device
    func isInputDevice(deviceID: AudioDeviceID) -> Bool {
        var inputChannels: UInt32 = 0
        var propertySize = UInt32(MemoryLayout<UInt32>.size)
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreams,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &inputChannels
        )

        if status != noErr {
            print("Error retrieving input channels for device \(deviceID): \(status)")
            return false
        }

        return inputChannels > 0
    }

    // Get the current input device
    func getCurrentInputDevice() -> AudioDeviceID? {
        var defaultInputDeviceID = AudioDeviceID(0)
        var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let result = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &defaultInputDeviceID
        )

        return (result == noErr) ? defaultInputDeviceID : nil
    }

    // Set the default input device
    func setDefaultInputDevice(deviceID: inout AudioDeviceID) {
        var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let result = AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            propertySize,
            &deviceID
        )

        if result != noErr {
            print("Failed to set default input device")
        }
    }

    // Check if the device is AirPods
    func isAirPods(deviceID: AudioDeviceID) -> Bool {
        guard let deviceName = getDeviceName(deviceID: deviceID) else {
            return false
        }
        return deviceName.contains("AirPods")
    }
}
