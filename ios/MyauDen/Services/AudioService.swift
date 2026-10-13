import AVFoundation
import Observation

/// Фонова музика для фокусу: два треки по колу. Грає й при заблокованому екрані (фоновий режим «audio»).
@Observable
final class MusicPlayer: NSObject, AVAudioPlayerDelegate {
    private(set) var isPlaying = false
    /// Користувач сам вимкнув музику кнопкою-нотою (запам'ятовується).
    var mutedByUser: Bool {
        didSet { UserDefaults.standard.set(mutedByUser, forKey: Keys.musicMuted) }
    }

    @ObservationIgnored private var player: AVAudioPlayer?
    @ObservationIgnored private var trackIndex = 0
    @ObservationIgnored private var fadeTimer: Timer?
    @ObservationIgnored private let tracks = ["focus-1", "focus-2"]
    private let volume: Float = 0.8

    override init() {
        mutedByUser = UserDefaults.standard.bool(forKey: Keys.musicMuted)
        super.init()
    }

    private func activateSession() {
        let s = AVAudioSession.sharedInstance()
        try? s.setCategory(.playback, mode: .default, options: [])
        try? s.setActive(true)
    }

    private func loadTrack() -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: tracks[trackIndex], withExtension: "mp3") else { return nil }
        let p = try? AVAudioPlayer(contentsOf: url)
        p?.delegate = self
        p?.volume = volume
        p?.prepareToPlay()
        return p
    }

    func play() {
        fadeTimer?.invalidate()
        activateSession()
        if player == nil { player = loadTrack() }
        player?.volume = volume
        isPlaying = player?.play() ?? false
    }

    func pause() {
        fadeTimer?.invalidate()
        player?.pause()
        isPlaying = false
    }

    /// Плавне затихання наприкінці сесії.
    func fadeOut() {
        guard let p = player, p.isPlaying else { return }
        fadeTimer?.invalidate()
        p.setVolume(0, fadeDuration: 1.4)
        fadeTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
            self?.player?.pause(); self?.player?.volume = self?.volume ?? 0.8
            self?.isPlaying = false
        }
    }

    /// Кнопка-нота: вмикає/вимикає музику, не чіпаючи таймер.
    func toggleByUser() {
        if isPlaying { mutedByUser = true; pause() } else { mutedByUser = false; play() }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        trackIndex = (trackIndex + 1) % tracks.count
        self.player = loadTrack()
        if isPlaying { self.player?.play() }
    }
}

/// Короткий «дзень» наприкінці фокусу (той самий, що й звук сповіщення).
enum Chime {
    private static var player: AVAudioPlayer?
    static func play() {
        guard let url = Bundle.main.url(forResource: "chime", withExtension: "wav") else { return }
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
        try? AVAudioSession.sharedInstance().setActive(true)
        player = try? AVAudioPlayer(contentsOf: url)
        player?.volume = 0.9
        player?.play()
    }
}
