#!/usr/bin/swift

import Foundation
import ShellOut

class airpodsDisableMicrophone {

    // MARK: - Properties

    let defaultInput = "Macbook Pro Microphone"
    lazy var inputs: [String] = ["USB  Camera", defaultInput] // Inputs by order of preference
    let timeout = 1.0

    // MARK: - Lifecycle Methods

    @discardableResult init() {

        Timer.scheduledTimer(timeInterval: timeout, target: self, selector: #selector(self.onTimeout(_:)), userInfo: nil, repeats: true)
    }

    // MARK: - Private Methods

    private func findAvailableInput() -> String {
        let allInputDevices = try! shellOut(to: "SwitchAudioSource -t input -a").components(separatedBy: .newlines)

        for input in inputs {
            if allInputDevices.contains(where: { $0.contains(input) }) {
                return input
            }
        }
    
        return defaultInput
    }

    @objc private func onTimeout(_ timer: Timer) {
       let currentInputDevice = try! shellOut(to: "SwitchAudioSource -t input -c")
       if currentInputDevice.contains("AirPods") {
           let betterInput = findAvailableInput()
           print("Input set to \(currentInputDevice), changing to \(betterInput) instead.")
           try! shellOut(to: "SwitchAudioSource -t input -s '\(betterInput)'")
       }
    }
}

do {
    try shellOut(to: "SwitchAudioSource -a")
} catch {
    print("Couldn't find SwitchAudioSource.")
    print("Please install switchaudio-osx via homebrew.")
    exit(1)
}

airpodsDisableMicrophone()
RunLoop.main.run(until: .distantFuture)
