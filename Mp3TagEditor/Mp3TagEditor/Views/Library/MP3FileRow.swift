import SwiftUI

// MARK: - MP3 File Row
struct MP3FileRow: View {
    let file: MP3File
    
    var body: some View {
        HStack(spacing: 14) {
            // Album Art Thumbnail
            albumArtThumbnail
            
            // File Info
            VStack(alignment: .leading, spacing: 4) {
                Text(file.displayTitle)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                
                Text(file.displayArtist)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    if let album = file.tag.album {
                        Text(album)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                    
                    if let year = file.tag.year {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        Text(year)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            
            Spacer(minLength: 4)
            
            // Tag Completeness Indicator
            VStack(alignment: .trailing, spacing: 4) {
                TagCompletenessRing(value: file.tagCompleteness, size: 24)
                
                Text(file.fileSizeFormatted)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var albumArtThumbnail: some View {
        Group {
            if let artData = file.tag.albumArtData,
               let image = UIImage(data: artData) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    LinearGradient(
                        colors: [.gray.opacity(0.3), .gray.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: "music.note")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
    }
}

// MARK: - Tag Completeness Ring
struct TagCompletenessRing: View {
    let value: Double
    let size: CGFloat
    
    var color: Color {
        switch value {
        case 0.8...1.0: return .green
        case 0.5..<0.8: return .orange
        default: return .red
        }
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 3)
            
            Circle()
                .trim(from: 0, to: value)
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            Text("\(Int(value * 100))")
                .font(.system(size: size * 0.35, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Large MP3 File Card (for featured display)
struct MP3FileCard: View {
    let file: MP3File
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Album Art
            Group {
                if let artData = file.tag.albumArtData,
                   let image = UIImage(data: artData) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    ZStack {
                        LinearGradient(
                            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        Image(systemName: "music.note")
                            .font(.system(size: 40))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
            .frame(height: 160)
            .clipped()
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(file.displayTitle)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(file.displayArtist)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(12)
        }
        .frame(width: 180)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }
}
