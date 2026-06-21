import AVFoundation

/// 안드로이드 TextToSpeech(Locale.US)에 대응. 항상 영어(en-US)로 읽는다.
final class Speaker {
    static let shared = Speaker()
    private let synth = AVSpeechSynthesizer()

    init() {
        // 무음(벨소리) 스위치가 켜져 있어도 음성이 나오도록 .playback 카테고리로 설정.
        try? AVAudioSession.sharedInstance()
            .setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
    }

    func speak(_ text: String) {
        try? AVAudioSession.sharedInstance().setActive(true)
        synth.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synth.speak(utterance)
    }
}
