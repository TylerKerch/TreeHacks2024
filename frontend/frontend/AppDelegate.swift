import Cocoa
import AVFoundation
import Speech

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var menuBarController: MenuBarController!
    let audioEngine = AVAudioEngine()
    var outputFile: AVAudioFile? = nil
    let outputURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("out.caf")

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Initialize the menu bar controller when the app finishes launching
        menuBarController = MenuBarController()
        
        if let mainWindow = NSApplication.shared.windows.first {
            mainWindow.close()
        }
        
        requestPermissions { [weak self] granted in
            guard granted else {
                print("Permissions not granted")
                return
            }
            
            self?.setupAudioRecording()
            
            // Stop recording after 5 seconds and then transcribe
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self?.stopRecordingAudio()
                self?.transcribeAudio()
            }
        }
    }
    
    func requestPermissions(completion: @escaping (Bool) -> Void) {
        let dispatchGroup = DispatchGroup()
        var micAccess = false
        var speechAccess = false
        
        dispatchGroup.enter()
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            micAccess = granted
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        SFSpeechRecognizer.requestAuthorization { status in
            speechAccess = status == .authorized
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(micAccess && speechAccess)
        }
    }
    
    func setupAudioRecording() {
        let input = audioEngine.inputNode
        let bus = 0
        let inputFormat = input.inputFormat(forBus: bus)

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
    
    func transcribeAudio() {
        guard let recognizer = SFSpeechRecognizer() else {
            print("Speech recognition is not available for the current locale.")
            return
        }
        
        let request = SFSpeechURLRecognitionRequest(url: outputURL)
        recognizer.recognitionTask(with: request) { result, error in
            guard let result = result else {
                print("There was an error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            if result.isFinal {
                let transcription = result.bestTranscription.formattedString
                print("Transcription: \(transcription)")
            }
        }
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
