import Cocoa
import AVFoundation
import Speech

class VoiceRecorder {
    var audioEngine: AVAudioEngine
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    var speechRecognizer: SFSpeechRecognizer?
    var finalTranscription: String = ""
    
    init() {
        audioEngine = AVAudioEngine()
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    }
    
    func startRecording() {
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

        recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            var isFinal = false

            if let result = result {
//                print("Transcription: \(result.bestTranscription.formattedString)")
                self?.finalTranscription = result.bestTranscription.formattedString
                isFinal = result.isFinal
            }

            if error != nil || isFinal {
                self?.audioEngine.stop()
                self?.audioEngine.inputNode.removeTap(onBus: 0)
                self?.recognitionRequest = nil
                self?.recognitionTask = nil
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
    
    func stopRecording() {
        print("Final transcription:\n \(finalTranscription)")
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        print("Finished recording")
    }
}
