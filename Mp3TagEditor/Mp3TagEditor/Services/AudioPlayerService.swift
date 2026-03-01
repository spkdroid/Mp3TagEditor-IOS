import Foundation
import AVFoundation
import Combine

// MARK: - Audio Player Service
@MainActor
final class AudioPlayerService: NSObject, ObservableObject {
    @Published var currentFile: MP3File?
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var progress: Double = 0
    @Published var isLoading: Bool = false
    
    private var player: AVAudioPlayer?
    private var timer: Timer?
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    // MARK: - Audio Session
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }
    
    // MARK: - Playback Controls
    
    func play(file: MP3File) {
        // If same file, just resume
        if currentFile?.id == file.id, let player = player {
            player.play()
            isPlaying = true
            startTimer()
            return
        }
        
        isLoading = true
        stop()
        
        do {
            let accessing = file.url.startAccessingSecurityScopedResource()
            
            player = try AVAudioPlayer(contentsOf: file.url)
            player?.delegate = self
            player?.prepareToPlay()
            player?.play()
            
            currentFile = file
            duration = player?.duration ?? 0
            isPlaying = true
            isLoading = false
            
            startTimer()
            
            if accessing {
                // Keep resource access for playback duration
            }
        } catch {
            print("Playback failed: \(error)")
            isLoading = false
            currentFile = nil
        }
    }
    
    func togglePlayPause() {
        guard let player = player else { return }
        
        if player.isPlaying {
            player.pause()
            isPlaying = false
            stopTimer()
        } else {
            player.play()
            isPlaying = true
            startTimer()
        }
    }
    
    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        currentTime = 0
        progress = 0
        stopTimer()
    }
    
    func dismiss() {
        stop()
        currentFile = nil
    }
    
    func seek(to time: TimeInterval) {
        player?.currentTime = time
        currentTime = time
        updateProgress()
    }
    
    func seekToProgress(_ progress: Double) {
        let time = duration * progress
        seek(to: time)
    }
    
    func skipForward(_ seconds: TimeInterval = 15) {
        let newTime = min(currentTime + seconds, duration)
        seek(to: newTime)
    }
    
    func skipBackward(_ seconds: TimeInterval = 15) {
        let newTime = max(currentTime - seconds, 0)
        seek(to: newTime)
    }
    
    // MARK: - Timer
    
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateProgress()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateProgress() {
        guard let player = player else { return }
        currentTime = player.currentTime
        duration = player.duration
        progress = duration > 0 ? currentTime / duration : 0
    }
    
    // MARK: - Formatting
    
    static func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - AVAudioPlayerDelegate
extension AudioPlayerService: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
            self.currentTime = 0
            self.progress = 0
            self.stopTimer()
        }
    }
    
    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            self.isPlaying = false
            self.stopTimer()
        }
    }
}
