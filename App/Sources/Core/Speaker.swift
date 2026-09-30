import AVFoundation

/// Model voice for a tapped word (system TTS).
enum Speaker {
    private static let synth = AVSpeechSynthesizer()
    static func say(_ text: String) {
        let u = AVSpeechUtterance(string: text)
        u.voice = AVSpeechSynthesisVoice(language: "en-US"); u.rate = 0.4
        synth.speak(u)
    }
}
