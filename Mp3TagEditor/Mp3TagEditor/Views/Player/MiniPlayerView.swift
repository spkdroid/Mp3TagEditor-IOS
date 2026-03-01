import SwiftUI

// MARK: - Mini Player View
struct MiniPlayerView: View {
    @EnvironmentObject private var playerService: AudioPlayerService
    @State private var showingFullPlayer = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(.quaternary)
                    
                    Rectangle()
                        .fill(.tint)
                        .frame(width: geometry.size.width * playerService.progress)
                }
            }
            .frame(height: 3)
            
            HStack(spacing: 12) {
                // Album Art
                if let file = playerService.currentFile {
                    miniAlbumArt(for: file)
                }
                
                // Track Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(playerService.currentFile?.displayTitle ?? "")
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                    
                    Text(playerService.currentFile?.displayArtist ?? "")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Controls
                HStack(spacing: 16) {
                    Button {
                        playerService.togglePlayPause()
                    } label: {
                        Image(systemName: playerService.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title2)
                            .contentTransition(.symbolEffect(.replace))
                    }
                    
                    Button {
                        playerService.dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.15), radius: 8, y: -2)
        .padding(.horizontal, 8)
        .onTapGesture {
            showingFullPlayer = true
        }
        .sheet(isPresented: $showingFullPlayer) {
            FullPlayerView()
                .environmentObject(playerService)
        }
    }
    
    private func miniAlbumArt(for file: MP3File) -> some View {
        Group {
            if let artData = file.tag.albumArtData,
               let image = UIImage(data: artData) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    LinearGradient(
                        colors: [.blue.opacity(0.4), .purple.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: "music.note")
                        .font(.caption)
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Full Player View
struct FullPlayerView: View {
    @EnvironmentObject private var playerService: AudioPlayerService
    @Environment(\.dismiss) private var dismiss
    @State private var isDraggingSlider = false
    @State private var dragProgress: Double = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                
                // Album Art
                albumArtView
                
                // Track Info
                VStack(spacing: 6) {
                    Text(playerService.currentFile?.displayTitle ?? "Unknown")
                        .font(.title2.bold())
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    
                    Text(playerService.currentFile?.displayArtist ?? "Unknown Artist")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    
                    if let album = playerService.currentFile?.tag.album {
                        Text(album)
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 20)
                
                // Progress Slider
                VStack(spacing: 4) {
                    Slider(
                        value: isDraggingSlider ? $dragProgress : $playerService.progress,
                        in: 0...1
                    ) { editing in
                        isDraggingSlider = editing
                        if !editing {
                            playerService.seekToProgress(dragProgress)
                        }
                    }
                    .tint(.primary)
                    
                    HStack {
                        Text(AudioPlayerService.formatTime(playerService.currentTime))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Text("-" + AudioPlayerService.formatTime(max(0, playerService.duration - playerService.currentTime)))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                
                // Playback Controls
                HStack(spacing: 40) {
                    Button {
                        playerService.skipBackward()
                    } label: {
                        Image(systemName: "gobackward.15")
                            .font(.title)
                    }
                    
                    Button {
                        playerService.togglePlayPause()
                        HapticManager.shared.impact(.medium)
                    } label: {
                        Image(systemName: playerService.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 64))
                            .contentTransition(.symbolEffect(.replace))
                    }
                    
                    Button {
                        playerService.skipForward()
                    } label: {
                        Image(systemName: "goforward.15")
                            .font(.title)
                    }
                }
                .foregroundStyle(.primary)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.down.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .presentationDragIndicator(.visible)
    }
    
    private var albumArtView: some View {
        Group {
            if let artData = playerService.currentFile?.tag.albumArtData,
               let image = UIImage(data: artData) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    LinearGradient(
                        colors: [.blue.opacity(0.4), .purple.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: "music.note")
                        .font(.system(size: 60))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
        .frame(width: 280, height: 280)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.25), radius: 20, y: 10)
        .scaleEffect(playerService.isPlaying ? 1.0 : 0.92)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: playerService.isPlaying)
    }
}
