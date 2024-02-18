//
//  TextReader.swift
//  frontend
//
//  Created by Sarvesh Phoenix on 2/17/24.
//

import Foundation
import AVFoundation

class TextReader {
    
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    init() {
        // TODO
    }
    
    func readText(s: String) {
        let utterance = AVSpeechUtterance(string: s)
                
        // Configure properties of the utterance as needed:
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US") // Set to the appropriate language
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate // Adjust the speech rate as needed
        
        // Stop any ongoing speech and start speaking the new text
        speechSynthesizer.stopSpeaking(at: .immediate)
        speechSynthesizer.speak(utterance)
    }
    
}

