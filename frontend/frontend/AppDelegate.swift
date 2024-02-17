//
//  AppDelegate.swift
//  frontend
//
//  Created by Samuel Yuan on 2/17/24.
//

import Cocoa
import AVFoundation

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var menuBarController: MenuBarController!
    let audioEngine = AVAudioEngine()
    var outputFile: AVAudioFile? = nil

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Initialize the menu bar controller when the app finishes launching
        menuBarController = MenuBarController()
        
        if let mainWindow = NSApplication.shared.windows.first {
            mainWindow.close()
        }
        
        // Start recording audio
        startRecordingAudio()
    }
    
    func startRecordingAudio() {
        // Ensure the app has permission to use the microphone
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized: // The user has previously granted access to the microphone.
            setupAudioRecording()
        case .notDetermined: // The user has not yet been asked for microphone access.
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.setupAudioRecording()
                    }
                }
            }
        default: // The user has previously denied access.
            return
        }
    }
    
    func setupAudioRecording() {
        let input = audioEngine.inputNode
        let bus = 0
        let inputFormat = input.inputFormat(forBus: bus)

        let outputURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("out.caf")
        print("writing to \(outputURL)")

        do {
            outputFile = try AVAudioFile(forWriting: outputURL, settings: inputFormat.settings, commonFormat: inputFormat.commonFormat, interleaved: inputFormat.isInterleaved)

            input.installTap(onBus: bus, bufferSize: 512, format: inputFormat) { (buffer, time) in
                do {
                    try self.outputFile?.write(from: buffer)
                } catch {
                    print("Error writing audio data: \(error)")
                }
            }

            try audioEngine.start()
        } catch {
            print("Could not start audio engine: \(error)")
        }

        // Example: Stop recording after 5 seconds (adjust as needed)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.stopRecordingAudio()
        }
    }
    
    func stopRecordingAudio() {
        print("Finish recording")
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        outputFile = nil
    }
    
    @objc func readScreen() {
        // Code to read screen content goes here
    }

    @objc func moveCursor() {
        // Code to move cursor goes here
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }


}

