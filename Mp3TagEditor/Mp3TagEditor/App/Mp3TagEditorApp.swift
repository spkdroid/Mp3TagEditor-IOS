import SwiftUI

@main
struct Mp3TagEditorApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(appState.preferredColorScheme)
                .tint(appState.accentColor)
        }
    }
}

// MARK: - App State
@MainActor
final class AppState: ObservableObject {
    @AppStorage("prefersDarkMode") var prefersDarkMode: Bool = false
    @AppStorage("accentColorHex") var accentColorHex: String = "#007AFF"
    @AppStorage("hapticFeedbackEnabled") var hapticFeedbackEnabled: Bool = true
    @AppStorage("autoSaveEnabled") var autoSaveEnabled: Bool = false
    @AppStorage("sortOption") var sortOption: SortOption = .title
    @AppStorage("sortAscending") var sortAscending: Bool = true
    
    var preferredColorScheme: ColorScheme? {
        prefersDarkMode ? .dark : nil
    }
    
    var accentColor: Color {
        Color(hex: accentColorHex) ?? .blue
    }
}

// MARK: - Sort Options
enum SortOption: String, CaseIterable, Codable {
    case title = "Title"
    case artist = "Artist"
    case album = "Album"
    case year = "Year"
    case dateAdded = "Date Added"
    case fileSize = "File Size"
}
