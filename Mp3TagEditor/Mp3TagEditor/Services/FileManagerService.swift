import Foundation
import UniformTypeIdentifiers

// MARK: - File Manager Service
final class FileManagerService {
    static let shared = FileManagerService()
    
    private let fileManager = FileManager.default
    private let libraryKey = "mp3_library_bookmarks"
    private let historyKey = "edit_history"
    
    private init() {}
    
    // MARK: - App Documents Directory
    
    var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    var appSupportDirectory: URL {
        let url = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Mp3TagEditor")
        try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
    
    // MARK: - File Import
    
    func importFile(from sourceURL: URL) throws -> URL {
        let accessing = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }
        
        let destURL = documentsDirectory.appendingPathComponent(sourceURL.lastPathComponent)
        
        // If file already exists, create unique name
        let finalURL = uniqueURL(for: destURL)
        
        try fileManager.copyItem(at: sourceURL, to: finalURL)
        
        return finalURL
    }
    
    func importFiles(from sourceURLs: [URL]) throws -> [URL] {
        return try sourceURLs.map { try importFile(from: $0) }
    }
    
    // MARK: - File Operations
    
    func deleteFile(at url: URL) throws {
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }
    
    func renameFile(at url: URL, to newName: String) throws -> URL {
        let newURL = url.deletingLastPathComponent().appendingPathComponent(newName)
        let finalURL = uniqueURL(for: newURL)
        try fileManager.moveItem(at: url, to: finalURL)
        return finalURL
    }
    
    func fileExists(at url: URL) -> Bool {
        fileManager.fileExists(atPath: url.path)
    }
    
    func fileSize(at url: URL) -> Int64 {
        let attributes = try? fileManager.attributesOfItem(atPath: url.path)
        return attributes?[.size] as? Int64 ?? 0
    }
    
    // MARK: - Security Scoped Bookmarks
    
    func saveBookmark(for url: URL) throws -> Data {
        return try url.bookmarkData(
            options: .minimalBookmark,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
    }
    
    func resolveBookmark(_ bookmarkData: Data) throws -> URL {
        var isStale = false
        let url = try URL(
            resolvingBookmarkData: bookmarkData,
            options: .withoutUI,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
        
        if isStale {
            // Re-create bookmark
            _ = try saveBookmark(for: url)
        }
        
        return url
    }
    
    // MARK: - Library Persistence
    
    func saveLibrary(_ files: [MP3File]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        if let data = try? encoder.encode(files) {
            UserDefaults.standard.set(data, forKey: libraryKey)
        }
    }
    
    func loadLibrary() -> [MP3File] {
        guard let data = UserDefaults.standard.data(forKey: libraryKey) else { return [] }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return (try? decoder.decode([MP3File].self, from: data)) ?? []
    }
    
    // MARK: - Edit History
    
    func saveEditHistory(_ entries: [EditHistoryEntry]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        if let data = try? encoder.encode(entries) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }
    
    func loadEditHistory() -> [EditHistoryEntry] {
        guard let data = UserDefaults.standard.data(forKey: historyKey) else { return [] }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return (try? decoder.decode([EditHistoryEntry].self, from: data)) ?? []
    }
    
    // MARK: - Scan Directory for MP3s
    
    func scanDirectory(_ url: URL) throws -> [URL] {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        let contents = try fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        )
        
        return contents.filter { $0.pathExtension.lowercased() == "mp3" }
    }
    
    // MARK: - Helpers
    
    private func uniqueURL(for url: URL) -> URL {
        guard fileManager.fileExists(atPath: url.path) else { return url }
        
        let directory = url.deletingLastPathComponent()
        let name = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension
        
        var counter = 1
        var newURL: URL
        
        repeat {
            newURL = directory.appendingPathComponent("\(name) (\(counter)).\(ext)")
            counter += 1
        } while fileManager.fileExists(atPath: newURL.path)
        
        return newURL
    }
}

// MARK: - UTType Extension
extension UTType {
    static let mp3 = UTType(filenameExtension: "mp3") ?? .audio
}
