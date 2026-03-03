import SwiftUI

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
