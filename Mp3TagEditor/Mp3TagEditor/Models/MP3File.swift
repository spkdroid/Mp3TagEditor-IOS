import Foundation
import SwiftUI

// MARK: - MP3 File Model
struct MP3File: Identifiable, Hashable, Codable {
    let id: UUID
    let url: URL
    let fileName: String
    let fileSize: Int64
    let dateAdded: Date
    var dateModified: Date
    var tag: ID3Tag
    var bookmarkData: Data?
    
    // Computed properties
    var fileSizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
    
    var displayTitle: String {
        tag.title ?? fileName.replacingOccurrences(of: ".mp3", with: "")
    }
    
    var displayArtist: String {
        tag.artist ?? "Unknown Artist"
    }
    
    var displayAlbum: String {
        tag.album ?? "Unknown Album"
    }
    
    var displayYear: String {
        tag.year ?? ""
    }
    
    var tagCompleteness: Double {
        let fields: [String?] = [tag.title, tag.artist, tag.album, tag.year, tag.genre, tag.trackNumber]
        let filled = fields.compactMap { $0 }.filter { !$0.isEmpty }.count
        return Double(filled) / Double(fields.count)
    }
    
    var tagCompletenessColor: Color {
        switch tagCompleteness {
        case 0.8...1.0: return .green
        case 0.5..<0.8: return .orange
        default: return .red
        }
    }
    
    var hasAlbumArt: Bool {
        tag.hasAlbumArt
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: MP3File, rhs: MP3File) -> Bool {
        lhs.id == rhs.id
    }
    
    // Create from URL
    static func create(from url: URL) throws -> MP3File {
        let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey, .creationDateKey, .contentModificationDateKey])
        
        var bookmarkData: Data? = nil
        if url.startAccessingSecurityScopedResource() {
            bookmarkData = try? url.bookmarkData(options: .minimalBookmark,
                                                  includingResourceValuesForKeys: nil,
                                                  relativeTo: nil)
        }
        
        let tag = try ID3Parser.parse(url: url)
        
        return MP3File(
            id: UUID(),
            url: url,
            fileName: url.lastPathComponent,
            fileSize: Int64(resourceValues.fileSize ?? 0),
            dateAdded: Date(),
            dateModified: resourceValues.contentModificationDate ?? Date(),
            tag: tag,
            bookmarkData: bookmarkData
        )
    }
}

// MARK: - Edit History Entry
struct EditHistoryEntry: Identifiable, Codable {
    let id: UUID
    let fileId: UUID
    let fileName: String
    let editDate: Date
    let fieldName: String
    let oldValue: String?
    let newValue: String?
    
    init(fileId: UUID, fileName: String, fieldName: String, oldValue: String?, newValue: String?) {
        self.id = UUID()
        self.fileId = fileId
        self.fileName = fileName
        self.editDate = Date()
        self.fieldName = fieldName
        self.oldValue = oldValue
        self.newValue = newValue
    }
}

// MARK: - Batch Edit Operation
struct BatchEditOperation: Identifiable {
    let id = UUID()
    var field: BatchEditField
    var value: String
    var enabled: Bool = true
}

enum BatchEditField: String, CaseIterable, Identifiable {
    case artist = "Artist"
    case album = "Album"
    case albumArtist = "Album Artist"
    case year = "Year"
    case genre = "Genre"
    case composer = "Composer"
    case publisher = "Publisher"
    case copyright = "Copyright"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .artist: return "person.fill"
        case .album: return "square.stack.fill"
        case .albumArtist: return "person.2.fill"
        case .year: return "calendar"
        case .genre: return "guitars.fill"
        case .composer: return "music.quarternote.3"
        case .publisher: return "building.2.fill"
        case .copyright: return "c.circle.fill"
        }
    }
}

// MARK: - Import Source
enum ImportSource: String, CaseIterable, Identifiable {
    case files = "Files"
    case folder = "Folder"
    case wifiUpload = "Wi-Fi Upload"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .files: return "doc.badge.plus"
        case .folder: return "folder.badge.plus"
        case .wifiUpload: return "wifi"
        }
    }
    
    var description: String {
        switch self {
        case .files: return "Import individual MP3 files"
        case .folder: return "Import all MP3 files from a folder"
        case .wifiUpload: return "Upload MP3 files from browser on same network"
        }
    }
}

// MARK: - Filter Options
struct FilterOptions {
    var hasAlbumArt: Bool? = nil
    var hasTitle: Bool? = nil
    var hasArtist: Bool? = nil
    var minCompleteness: Double? = nil
    var genre: String? = nil
    var year: String? = nil
}
