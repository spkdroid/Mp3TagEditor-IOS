import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var libraryVM = LibraryViewModel()
    @StateObject private var playerService = AudioPlayerService()
    @State private var selectedTab: Tab = .library
    @State private var showingSettings = false
    
    enum Tab: String, CaseIterable {
        case library = "Library"
        case recentEdits = "Recent"
        case settings = "Settings"
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                LibraryView()
                    .environmentObject(libraryVM)
                    .environmentObject(playerService)
                    .tag(Tab.library)
                    .tabItem {
                        Label("Library", systemImage: "music.note.list")
                    }
                
                RecentEditsView()
                    .environmentObject(libraryVM)
                    .environmentObject(playerService)
                    .tag(Tab.recentEdits)
                    .tabItem {
                        Label("Recent", systemImage: "clock.arrow.circlepath")
                    }
                
                SettingsView()
                    .tag(Tab.settings)
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
            }
            
            // Mini Player overlay
            if playerService.currentFile != nil {
                MiniPlayerView()
                    .environmentObject(playerService)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 49) // Tab bar height
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: playerService.currentFile != nil)
    }
}

// MARK: - Recent Edits View
struct RecentEditsView: View {
    @EnvironmentObject private var libraryVM: LibraryViewModel
    @EnvironmentObject private var playerService: AudioPlayerService
    
    var body: some View {
        NavigationStack {
            Group {
                if libraryVM.recentlyEdited.isEmpty {
                    ContentUnavailableView(
                        "No Recent Edits",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Files you edit will appear here")
                    )
                } else {
                    List {
                        ForEach(libraryVM.recentlyEdited) { file in
                            NavigationLink(value: file) {
                                MP3FileRow(file: file)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .navigationDestination(for: MP3File.self) { file in
                        TagEditorView(file: file)
                            .environmentObject(libraryVM)
                            .environmentObject(playerService)
                    }
                }
            }
            .navigationTitle("Recent Edits")
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Toggle("Dark Mode", isOn: $appState.prefersDarkMode)
                    
                    HStack {
                        Text("Accent Color")
                        Spacer()
                        HStack(spacing: 8) {
                            ForEach(accentColors, id: \.self) { color in
                                Circle()
                                    .fill(Color(hex: color) ?? .blue)
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(.white, lineWidth: 2)
                                            .opacity(appState.accentColorHex == color ? 1 : 0)
                                    )
                                    .shadow(color: (Color(hex: color) ?? .blue).opacity(0.4), radius: appState.accentColorHex == color ? 4 : 0)
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            appState.accentColorHex = color
                                        }
                                        HapticManager.shared.impact(.light)
                                    }
                            }
                        }
                    }
                }
                
                Section("Behavior") {
                    Toggle("Haptic Feedback", isOn: $appState.hapticFeedbackEnabled)
                    Toggle("Auto-Save Changes", isOn: $appState.autoSaveEnabled)
                    
                    Picker("Default Sort", selection: $appState.sortOption) {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    
                    Toggle("Sort Ascending", isOn: $appState.sortAscending)
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Supported Formats")
                        Spacer()
                        Text("MP3 (ID3v1, ID3v2)")
                            .foregroundStyle(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://github.com")!) {
                        HStack {
                            Text("Source Code")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Section("Data") {
                    Button("Clear Recent Edits", role: .destructive) {
                        // Clear recent edits
                    }
                    
                    Button("Reset All Settings", role: .destructive) {
                        appState.prefersDarkMode = false
                        appState.accentColorHex = "#007AFF"
                        appState.hapticFeedbackEnabled = true
                        appState.autoSaveEnabled = false
                        appState.sortOption = .title
                        appState.sortAscending = true
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
    
    private var accentColors: [String] {
        ["#007AFF", "#FF2D55", "#FF9500", "#34C759", "#AF52DE", "#FF6B6B"]
    }
}
