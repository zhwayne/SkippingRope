//
//  SpeechSynthesizer.swift
//  BlueCentralExample
//
//  Created by iya on 2023/3/30.
//

import Foundation
import AVFoundation
import Combine

struct SpeechSynthesizer {
    
    func speak(_ string: String) async {
        let utterance = AVSpeechUtterance(string: string)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh_CN")
        
        let synthesizer = AVSpeechSynthesizer()
        let delegate = SpeechSynthesizerDelegate()
        synthesizer.delegate = delegate
        
        await withCheckedContinuation { continuation in
            delegate.speakCompletion = {
                continuation.resume()
            }
            synthesizer.speak(utterance)
        }
    }
}

class SpeechSynthesizerDelegate: NSObject, AVSpeechSynthesizerDelegate {
    var speakCompletion: (() -> Void)?
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        speakCompletion?()
    }
}
