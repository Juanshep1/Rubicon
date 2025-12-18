import Foundation
import AVFoundation
import SwiftUI

/// Manages all audio playback for the Rubicon game
@MainActor
public final class AudioManager: ObservableObject {
    public static let shared = AudioManager()

    // MARK: - Settings

    @AppStorage("soundEffectsEnabled") public var soundEffectsEnabled = true
    @AppStorage("musicEnabled") public var musicEnabled = true
    @AppStorage("soundEffectsVolume") public var soundEffectsVolume: Double = 0.7
    @AppStorage("musicVolume") public var musicVolume: Double = 0.3

    // MARK: - Audio Players

    private var musicPlayer: AVAudioPlayer?
    private var sfxPlayers: [SoundEffect: AVAudioPlayer] = [:]

    // MARK: - Sound Effects Enum

    public enum SoundEffect: String, CaseIterable {
        case stoneMove = "stone_move"
        case stoneSelect = "select"
        case lock = "lock"
        case victory = "victory"

        var filename: String { rawValue }
    }

    // MARK: - Initialization

    private init() {
        setupAudioSession()
        preloadSoundEffects()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }

    private func preloadSoundEffects() {
        for effect in SoundEffect.allCases {
            if let url = Bundle.main.url(forResource: effect.filename, withExtension: "mp3") {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay()
                    sfxPlayers[effect] = player
                } catch {
                    print("Failed to load sound effect \(effect.rawValue): \(error)")
                }
            } else {
                print("Sound file not found: \(effect.filename).mp3")
            }
        }
    }

    // MARK: - Sound Effects

    public func playSound(_ effect: SoundEffect) {
        guard soundEffectsEnabled else { return }

        if let player = sfxPlayers[effect] {
            player.volume = Float(soundEffectsVolume)
            player.currentTime = 0
            player.play()
        }
    }

    /// Play stone placement/movement sound
    public func playStoneMove() {
        playSound(.stoneMove)
    }

    /// Play selection sound
    public func playSelect() {
        playSound(.stoneSelect)
    }

    /// Play pattern lock sound
    public func playLock() {
        playSound(.lock)
    }

    /// Play victory sound
    public func playVictory() {
        playSound(.victory)
    }

    // MARK: - Background Music

    public func startBackgroundMusic() {
        guard musicEnabled else { return }
        guard musicPlayer == nil || musicPlayer?.isPlaying == false else { return }

        if let url = Bundle.main.url(forResource: "background_music", withExtension: "mp3") {
            do {
                musicPlayer = try AVAudioPlayer(contentsOf: url)
                musicPlayer?.numberOfLoops = -1 // Loop indefinitely
                musicPlayer?.volume = Float(musicVolume)
                musicPlayer?.prepareToPlay()
                musicPlayer?.play()
            } catch {
                print("Failed to play background music: \(error)")
            }
        } else {
            print("Background music file not found")
        }
    }

    public func stopBackgroundMusic() {
        musicPlayer?.stop()
        musicPlayer = nil
    }

    public func pauseBackgroundMusic() {
        musicPlayer?.pause()
    }

    public func resumeBackgroundMusic() {
        guard musicEnabled else { return }
        musicPlayer?.play()
    }

    public func updateMusicVolume() {
        musicPlayer?.volume = Float(musicVolume)
    }

    public func updateSoundEffectsVolume() {
        for player in sfxPlayers.values {
            player.volume = Float(soundEffectsVolume)
        }
    }

    // MARK: - Toggle Methods

    public func toggleSoundEffects() {
        soundEffectsEnabled.toggle()
    }

    public func toggleMusic() {
        musicEnabled.toggle()
        if musicEnabled {
            startBackgroundMusic()
        } else {
            stopBackgroundMusic()
        }
    }
}
