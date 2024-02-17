import Cocoa
import AVFoundation
import Speech

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var menuBarController: MenuBarController!
    let audioEngine = AVAudioEngine()
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

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
            self?.startTranscribing()
        }
    }
    
    func requestPermissions(completion: @escaping (Bool) -> Void) {
        var isMicrophoneAuthorized = false
        var isSpeechAuthorized = false

        AVCaptureDevice.requestAccess(for: .audio) { granted in
            isMicrophoneAuthorized = granted

            SFSpeechRecognizer.requestAuthorization { authStatus in
                isSpeechAuthorized = (authStatus == .authorized)

                DispatchQueue.main.async {
                    completion(isMicrophoneAuthorized && isSpeechAuthorized)
                }
            }
        }
    }
    
    func startTranscribing() {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            print("Speech recognition not available.")
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest object")
        }
        recognitionRequest.shouldReportPartialResults = true

        recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false

            if let result = result {
                print("Transcription: \(result.bestTranscription.formattedString)")
                isFinal = result.isFinal
            }

            if error != nil || isFinal {
                self.audioEngine.stop()
                self.audioEngine.inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
            }
        }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 512, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error: \(error)")
        }
    }
    
    func stopTranscribing() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
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
