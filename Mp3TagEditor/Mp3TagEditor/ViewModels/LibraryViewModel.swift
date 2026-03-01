import Foundation
import SwiftUI
import UniformTypeIdentifiers
import Combine

// MARK: - Library ViewModel
@MainActor
final class LibraryViewModel: ObservableObject {
    // Published properties
    @Published var files: [MP3File] = []
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var loadingMessage: String = ""
    @Published var showingImportPicker: Bool = false
    @Published var showingFolderPicker: Bool = false
    @Published var showingBatchEdit: Bool = false
    @Published var selectedFiles: Set<UUID> = Set()
    @Published var isSelectionMode: Bool = false
    @Published var sortOption: SortOption = .title
    @Published var sortAscending: Bool = true
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var editHistory: [EditHistoryEntry] = []
    @Published var filterOptions = FilterOptions()
    @Published var showingFilterSheet: Bool = false
    
    private let fileService = FileManagerService.shared
    
    // MARK: - Computed Properties
    
    var filteredFiles: [MP3File] {
        var result = files
        
        // Apply search
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { file in
                file.displayTitle.lowercased().contains(query) ||
                file.displayArtist.lowercased().contains(query) ||
                file.displayAlbum.lowercased().contains(query) ||
                file.fileName.lowercased().contains(query) ||
                (file.tag.genre?.lowercased().contains(query) ?? false)
            }
        }
        
        // Apply filters
        if let hasArt = filterOptions.hasAlbumArt {
            result = result.filter { $0.hasAlbumArt == hasArt }
        }
        if let genre = filterOptions.genre, !genre.isEmpty {
            result = result.filter { $0.tag.genre?.lowercased() == genre.lowercased() }
        }
        if let year = filterOptions.year, !year.isEmpty {
            result = result.filter { $0.tag.year == year }
        }
        if let minComplete = filterOptions.minCompleteness {
            result = result.filter { $0.tagCompleteness >= minComplete }
        }
        
        // Apply sort
        result.sort { a, b in
            let comparison: Bool
            switch sortOption {
            case .title:
                comparison = a.displayTitle.localizedCaseInsensitiveCompare(b.displayTitle) == .orderedAscending
            case .artist:
                comparison = a.displayArtist.localizedCaseInsensitiveCompare(b.displayArtist) == .orderedAscending
            case .album:
                comparison = a.displayAlbum.localizedCaseInsensitiveCompare(b.displayAlbum) == .orderedAscending
            case .year:
                comparison = (a.tag.year ?? "") < (b.tag.year ?? "")
            case .dateAdded:
                comparison = a.dateAdded > b.dateAdded
            case .fileSize:
                comparison = a.fileSize < b.fileSize
            }
            return sortAscending ? comparison : !comparison
        }
        
        return result
    }
    
    var recentlyEdited: [MP3File] {
        let recentFileIds = Set(editHistory.prefix(50).map { $0.fileId })
        return files.filter { recentFileIds.contains($0.id) }
            .sorted { a, b in
                let aDate = editHistory.first { $0.fileId == a.id }?.editDate ?? .distantPast
                let bDate = editHistory.first { $0.fileId == b.id }?.editDate ?? .distantPast
                return aDate > bDate
            }
    }
    
    var uniqueGenres: [String] {
        Array(Set(files.compactMap { $0.tag.genre })).sorted()
    }
    
    var uniqueYears: [String] {
        Array(Set(files.compactMap { $0.tag.year })).sorted().reversed()
    }
    
    var statistics: LibraryStatistics {
        LibraryStatistics(
            totalFiles: files.count,
            totalSize: files.reduce(0) { $0 + $1.fileSize },
            withAlbumArt: files.filter { $0.hasAlbumArt }.count,
            averageCompleteness: files.isEmpty ? 0 : files.reduce(0.0) { $0 + $1.tagCompleteness } / Double(files.count),
            uniqueArtists: Set(files.compactMap { $0.tag.artist }).count,
            uniqueAlbums: Set(files.compactMap { $0.tag.album }).count
        )
    }
    
    // MARK: - Initialization
    
    init() {
        loadLibrary()
    }
    
    // MARK: - File Import
    
    func importFiles(urls: [URL]) {
        isLoading = true
        loadingMessage = "Importing files..."
        
        Task {
            var imported: [MP3File] = []
            
            for (index, url) in urls.enumerated() {
                loadingMessage = "Importing \(index + 1) of \(urls.count)..."
                
                do {
                    let accessing = url.startAccessingSecurityScopedResource()
                    defer {
                        if accessing {
                            url.stopAccessingSecurityScopedResource()
                        }
                    }
                    
                    // Copy to app documents
                    let localURL = try fileService.importFile(from: url)
                    let file = try MP3File.create(from: localURL)
                    imported.append(file)
                } catch {
                    print("Failed to import \(url.lastPathComponent): \(error)")
                }
            }
            
            files.append(contentsOf: imported)
            saveLibrary()
            
            isLoading = false
            loadingMessage = ""
            
            HapticManager.shared.notification(.success)
        }
    }
    
    func importFolder(url: URL) {
        isLoading = true
        loadingMessage = "Scanning folder..."
        
        Task {
            do {
                let mp3URLs = try fileService.scanDirectory(url)
                importFiles(urls: mp3URLs)
            } catch {
                showError(message: "Failed to scan folder: \(error.localizedDescription)")
                isLoading = false
            }
        }
    }
    
    // MARK: - File Operations
    
    func deleteFile(_ file: MP3File) {
        try? fileService.deleteFile(at: file.url)
        files.removeAll { $0.id == file.id }
        selectedFiles.remove(file.id)
        saveLibrary()
        HapticManager.shared.notification(.warning)
    }
    
    func deleteSelectedFiles() {
        let toDelete = files.filter { selectedFiles.contains($0.id) }
        for file in toDelete {
            try? fileService.deleteFile(at: file.url)
        }
        files.removeAll { selectedFiles.contains($0.id) }
        selectedFiles.removeAll()
        isSelectionMode = false
        saveLibrary()
        HapticManager.shared.notification(.warning)
    }
    
    func updateFile(_ updatedFile: MP3File) {
        if let index = files.firstIndex(where: { $0.id == updatedFile.id }) {
            files[index] = updatedFile
            saveLibrary()
        }
    }
    
    // MARK: - Tag Operations
    
    func saveTags(for file: MP3File, newTag: ID3Tag) throws {
        let accessing = file.url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                file.url.stopAccessingSecurityScopedResource()
            }
        }
        
        try ID3Parser.write(tag: newTag, to: file.url)
        
        var updatedFile = file
        updatedFile.tag = newTag
        updatedFile.dateModified = Date()
        updateFile(updatedFile)
        
        HapticManager.shared.notification(.success)
    }
    
    func addEditHistory(entry: EditHistoryEntry) {
        editHistory.insert(entry, at: 0)
        if editHistory.count > 500 {
            editHistory = Array(editHistory.prefix(500))
        }
        fileService.saveEditHistory(editHistory)
    }
    
    // MARK: - Batch Operations
    
    func applyBatchEdit(operations: [BatchEditOperation], to fileIds: Set<UUID>) throws {
        let targetFiles = files.filter { fileIds.contains($0.id) }
        
        for file in targetFiles {
            var newTag = file.tag
            
            for operation in operations where operation.enabled {
                switch operation.field {
                case .artist: newTag.artist = operation.value
                case .album: newTag.album = operation.value
                case .albumArtist: newTag.albumArtist = operation.value
                case .year: newTag.year = operation.value
                case .genre: newTag.genre = operation.value
                case .composer: newTag.composer = operation.value
                case .publisher: newTag.publisher = operation.value
                case .copyright: newTag.copyright = operation.value
                }
            }
            
            try saveTags(for: file, newTag: newTag)
        }
    }
    
    func applyAlbumArtToSelected(imageData: Data) throws {
        let targetFiles = files.filter { selectedFiles.contains($0.id) }
        let mimeType = ImageService.mimeType(for: imageData)
        
        for file in targetFiles {
            var newTag = file.tag
            newTag.albumArtData = imageData
            newTag.albumArtMimeType = mimeType
            try saveTags(for: file, newTag: newTag)
        }
    }
    
    // MARK: - Selection
    
    func toggleSelection(for fileId: UUID) {
        if selectedFiles.contains(fileId) {
            selectedFiles.remove(fileId)
        } else {
            selectedFiles.insert(fileId)
        }
        HapticManager.shared.selection()
    }
    
    func selectAll() {
        selectedFiles = Set(filteredFiles.map { $0.id })
    }
    
    func deselectAll() {
        selectedFiles.removeAll()
    }
    
    func exitSelectionMode() {
        isSelectionMode = false
        selectedFiles.removeAll()
    }
    
    // MARK: - Persistence
    
    func saveLibrary() {
        fileService.saveLibrary(files)
    }
    
    private func loadLibrary() {
        files = fileService.loadLibrary()
        editHistory = fileService.loadEditHistory()
        
        // Verify files still exist
        files = files.filter { fileService.fileExists(at: $0.url) }
    }
    
    func refreshLibrary() {
        isLoading = true
        loadingMessage = "Refreshing..."
        
        Task {
            // Re-read tags for all files
            for (index, file) in files.enumerated() {
                if fileService.fileExists(at: file.url) {
                    if let newTag = try? ID3Parser.parse(url: file.url) {
                        files[index].tag = newTag
                    }
                }
            }
            
            // Remove missing files
            files = files.filter { fileService.fileExists(at: $0.url) }
            saveLibrary()
            
            isLoading = false
            loadingMessage = ""
        }
    }
    
    // MARK: - Error Handling
    
    func showError(message: String) {
        errorMessage = message
        showError = true
    }
    
    func clearFilters() {
        filterOptions = FilterOptions()
    }
}

// MARK: - Library Statistics
struct LibraryStatistics {
    let totalFiles: Int
    let totalSize: Int64
    let withAlbumArt: Int
    let averageCompleteness: Double
    let uniqueArtists: Int
    let uniqueAlbums: Int
    
    var totalSizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
    
    var completenessPercentage: String {
        String(format: "%.0f%%", averageCompleteness * 100)
    }
}
