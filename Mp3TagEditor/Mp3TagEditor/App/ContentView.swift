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
            AmbientBackground()

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
                    .padding(.bottom, 56)
            }
        }
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: playerService.currentFile != nil)
    }
}
