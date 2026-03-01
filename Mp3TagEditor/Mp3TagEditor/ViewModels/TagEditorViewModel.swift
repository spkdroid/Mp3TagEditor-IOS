import Foundation
import SwiftUI
import PhotosUI

// MARK: - Tag Editor ViewModel
@MainActor
final class TagEditorViewModel: ObservableObject {
    // Published tag fields
    @Published var title: String = ""
    @Published var artist: String = ""
    @Published var album: String = ""
    @Published var albumArtist: String = ""
    @Published var year: String = ""
    @Published var genre: String = ""
    @Published var trackNumber: String = ""
    @Published var discNumber: String = ""
    @Published var composer: String = ""
    @Published var comment: String = ""
    @Published var lyrics: String = ""
    @Published var bpm: String = ""
    @Published var encoder: String = ""
    @Published var copyright: String = ""
    @Published var publisher: String = ""
    @Published var originalArtist: String = ""
    @Published var isrc: String = ""
    
    // Album art
    @Published var albumArtData: Data?
    @Published var albumArtImage: UIImage?
    @Published var showingPhotoPicker: Bool = false
    @Published var showingArtOptions: Bool = false
    @Published var selectedPhotoItem: PhotosPickerItem?
    
    // State
    @Published var hasChanges: Bool = false
    @Published var isSaving: Bool = false
    @Published var saveError: String?
    @Published var showSaveError: Bool = false
    @Published var showSaveSuccess: Bool = false
    @Published var showingDiscardAlert: Bool = false
    @Published var showingAdvancedFields: Bool = false
    
    let file: MP3File
    private let originalTag: ID3Tag
    
    // MARK: - Initialization
    
    init(file: MP3File) {
        self.file = file
        self.originalTag = file.tag
        loadTagData()
    }
    
    private func loadTagData() {
        title = file.tag.title ?? ""
        artist = file.tag.artist ?? ""
        album = file.tag.album ?? ""
        albumArtist = file.tag.albumArtist ?? ""
        year = file.tag.year ?? ""
        genre = file.tag.genre ?? ""
        trackNumber = file.tag.trackNumber ?? ""
        discNumber = file.tag.discNumber ?? ""
        composer = file.tag.composer ?? ""
        comment = file.tag.comment ?? ""
        lyrics = file.tag.lyrics ?? ""
        bpm = file.tag.bpm ?? ""
        encoder = file.tag.encoder ?? ""
        copyright = file.tag.copyright ?? ""
        publisher = file.tag.publisher ?? ""
        originalArtist = file.tag.originalArtist ?? ""
        isrc = file.tag.isrc ?? ""
        
        albumArtData = file.tag.albumArtData
        if let data = albumArtData {
            albumArtImage = UIImage(data: data)
        }
    }
    
    // MARK: - Computed Properties
    
    var currentTag: ID3Tag {
        var tag = ID3Tag()
        tag.title = title.isEmpty ? nil : title
        tag.artist = artist.isEmpty ? nil : artist
        tag.album = album.isEmpty ? nil : album
        tag.albumArtist = albumArtist.isEmpty ? nil : albumArtist
        tag.year = year.isEmpty ? nil : year
        tag.genre = genre.isEmpty ? nil : genre
        tag.trackNumber = trackNumber.isEmpty ? nil : trackNumber
        tag.discNumber = discNumber.isEmpty ? nil : discNumber
        tag.composer = composer.isEmpty ? nil : composer
        tag.comment = comment.isEmpty ? nil : comment
        tag.lyrics = lyrics.isEmpty ? nil : lyrics
        tag.bpm = bpm.isEmpty ? nil : bpm
        tag.encoder = encoder.isEmpty ? nil : encoder
        tag.copyright = copyright.isEmpty ? nil : copyright
        tag.publisher = publisher.isEmpty ? nil : publisher
        tag.originalArtist = originalArtist.isEmpty ? nil : originalArtist
        tag.isrc = isrc.isEmpty ? nil : isrc
        tag.albumArtData = albumArtData
        tag.albumArtMimeType = albumArtData != nil ? ImageService.mimeType(for: albumArtData!) : nil
        tag.version = .v2_3
        return tag
    }
    
    var tagVersion: String {
        file.tag.version.rawValue
    }
    
    var fileInfo: String {
        "\(file.fileSizeFormatted) • \(file.tag.version.rawValue)"
    }
    
    var changedFields: [String] {
        var changes: [String] = []
        if title != (originalTag.title ?? "") { changes.append("Title") }
        if artist != (originalTag.artist ?? "") { changes.append("Artist") }
        if album != (originalTag.album ?? "") { changes.append("Album") }
        if year != (originalTag.year ?? "") { changes.append("Year") }
        if genre != (originalTag.genre ?? "") { changes.append("Genre") }
        if trackNumber != (originalTag.trackNumber ?? "") { changes.append("Track") }
        if albumArtData != originalTag.albumArtData { changes.append("Artwork") }
        return changes
    }
    
    // MARK: - Change Detection
    
    func checkForChanges() {
        hasChanges = currentTag != originalTag
    }
    
    // MARK: - Album Art
    
    func handlePhotoSelection() async {
        guard let item = selectedPhotoItem else { return }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                if let image = UIImage(data: data) {
                    // Resize and compress
                    let resized = ImageService.squareThumbnail(from: image, size: 600)
                    if let compressed = ImageService.compress(image: resized, maxSizeKB: 500) {
                        albumArtData = compressed
                        albumArtImage = UIImage(data: compressed)
                        checkForChanges()
                        HapticManager.shared.notification(.success)
                    }
                }
            }
        } catch {
            print("Failed to load photo: \(error)")
        }
    }
    
    func removeAlbumArt() {
        albumArtData = nil
        albumArtImage = nil
        checkForChanges()
        HapticManager.shared.impact(.medium)
    }
    
    // MARK: - Save
    
    func save(using libraryVM: LibraryViewModel) {
        isSaving = true
        
        Task {
            do {
                let tag = currentTag
                try libraryVM.saveTags(for: file, newTag: tag)
                
                // Record edit history
                for fieldName in changedFields {
                    let entry = EditHistoryEntry(
                        fileId: file.id,
                        fileName: file.fileName,
                        fieldName: fieldName,
                        oldValue: getOriginalValue(for: fieldName),
                        newValue: getCurrentValue(for: fieldName)
                    )
                    libraryVM.addEditHistory(entry: entry)
                }
                
                isSaving = false
                hasChanges = false
                showSaveSuccess = true
                HapticManager.shared.notification(.success)
                
                // Auto-dismiss success after delay
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                showSaveSuccess = false
            } catch {
                isSaving = false
                saveError = error.localizedDescription
                showSaveError = true
                HapticManager.shared.notification(.error)
            }
        }
    }
    
    // MARK: - Reset
    
    func resetToOriginal() {
        loadTagData()
        hasChanges = false
        HapticManager.shared.impact(.medium)
    }
    
    func clearAllFields() {
        title = ""
        artist = ""
        album = ""
        albumArtist = ""
        year = ""
        genre = ""
        trackNumber = ""
        discNumber = ""
        composer = ""
        comment = ""
        lyrics = ""
        bpm = ""
        encoder = ""
        copyright = ""
        publisher = ""
        originalArtist = ""
        isrc = ""
        albumArtData = nil
        albumArtImage = nil
        checkForChanges()
    }
    
    // MARK: - Helpers
    
    private func getOriginalValue(for field: String) -> String? {
        switch field {
        case "Title": return originalTag.title
        case "Artist": return originalTag.artist
        case "Album": return originalTag.album
        case "Year": return originalTag.year
        case "Genre": return originalTag.genre
        case "Track": return originalTag.trackNumber
        case "Artwork": return originalTag.hasAlbumArt ? "Has artwork" : "No artwork"
        default: return nil
        }
    }
    
    private func getCurrentValue(for field: String) -> String? {
        switch field {
        case "Title": return title.isEmpty ? nil : title
        case "Artist": return artist.isEmpty ? nil : artist
        case "Album": return album.isEmpty ? nil : album
        case "Year": return year.isEmpty ? nil : year
        case "Genre": return genre.isEmpty ? nil : genre
        case "Track": return trackNumber.isEmpty ? nil : trackNumber
        case "Artwork": return albumArtData != nil ? "Has artwork" : "No artwork"
        default: return nil
        }
    }
}
