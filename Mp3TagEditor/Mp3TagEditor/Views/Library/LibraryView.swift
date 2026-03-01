import SwiftUI
import UniformTypeIdentifiers

// MARK: - Library View
struct LibraryView: View {
    @EnvironmentObject private var libraryVM: LibraryViewModel
    @EnvironmentObject private var playerService: AudioPlayerService
    @EnvironmentObject private var appState: AppState
    @State private var showingImportSheet = false
    @State private var showingStats = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                if libraryVM.files.isEmpty && !libraryVM.isLoading {
                    emptyStateView
                } else {
                    fileListView
                }
                
                if libraryVM.isLoading {
                    LoadingOverlay(message: libraryVM.loadingMessage)
                }
            }
            .navigationTitle(libraryVM.isSelectionMode ? "\(libraryVM.selectedFiles.count) Selected" : "Library")
            .searchable(text: $libraryVM.searchText, prompt: "Search by title, artist, album...")
            .toolbar { toolbarContent }
            .sheet(isPresented: $showingImportSheet) {
                ImportOptionsView()
                    .environmentObject(libraryVM)
            }
            .sheet(isPresented: $libraryVM.showingFilterSheet) {
                FilterSheetView()
                    .environmentObject(libraryVM)
            }
            .sheet(isPresented: $showingStats) {
                LibraryStatsView(statistics: libraryVM.statistics)
            }
            .sheet(isPresented: $libraryVM.showingBatchEdit) {
                BatchEditView()
                    .environmentObject(libraryVM)
            }
            .fileImporter(
                isPresented: $libraryVM.showingImportPicker,
                allowedContentTypes: [.mp3, .audio],
                allowsMultipleSelection: true
            ) { result in
                handleFileImport(result)
            }
            .fileImporter(
                isPresented: $libraryVM.showingFolderPicker,
                allowedContentTypes: [.folder],
                allowsMultipleSelection: false
            ) { result in
                handleFolderImport(result)
            }
            .alert("Error", isPresented: $libraryVM.showError) {
                Button("OK") { }
            } message: {
                Text(libraryVM.errorMessage ?? "An unknown error occurred")
            }
            .refreshable {
                libraryVM.refreshLibrary()
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "music.note.list")
                .font(.system(size: 72))
                .foregroundStyle(.tertiary)
            
            VStack(spacing: 8) {
                Text("No MP3 Files")
                    .font(.title2.bold())
                
                Text("Import MP3 files to edit their tags")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                showingImportSheet = true
            } label: {
                Label("Import Files", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
    
    // MARK: - File List
    
    private var fileListView: some View {
        List(selection: libraryVM.isSelectionMode ? $libraryVM.selectedFiles : nil) {
            // Stats header
            if !libraryVM.isSelectionMode && libraryVM.searchText.isEmpty {
                statsHeaderView
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
            }
            
            ForEach(libraryVM.filteredFiles) { file in
                if libraryVM.isSelectionMode {
                    MP3FileRow(file: file)
                        .tag(file.id)
                } else {
                    NavigationLink(value: file) {
                        MP3FileRow(file: file)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            libraryVM.deleteFile(file)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        Button {
                            playerService.play(file: file)
                        } label: {
                            Label("Play", systemImage: "play.fill")
                        }
                        .tint(.blue)
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            libraryVM.isSelectionMode = true
                            libraryVM.toggleSelection(for: file.id)
                        } label: {
                            Label("Select", systemImage: "checkmark.circle")
                        }
                        .tint(.orange)
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationDestination(for: MP3File.self) { file in
            TagEditorView(file: file)
                .environmentObject(libraryVM)
                .environmentObject(playerService)
        }
        .environment(\.editMode, .constant(libraryVM.isSelectionMode ? .active : .inactive))
    }
    
    // MARK: - Stats Header
    
    private var statsHeaderView: some View {
        HStack(spacing: 12) {
            StatCard(
                value: "\(libraryVM.files.count)",
                label: "Files",
                icon: "music.note",
                color: .blue
            )
            
            StatCard(
                value: libraryVM.statistics.totalSizeFormatted,
                label: "Total Size",
                icon: "internaldrive",
                color: .purple
            )
            
            StatCard(
                value: libraryVM.statistics.completenessPercentage,
                label: "Complete",
                icon: "checkmark.circle",
                color: .green
            )
        }
        .onTapGesture {
            showingStats = true
        }
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if libraryVM.isSelectionMode {
                Button("Done") {
                    libraryVM.exitSelectionMode()
                }
                .bold()
            } else {
                Menu {
                    Button {
                        showingImportSheet = true
                    } label: {
                        Label("Import Files", systemImage: "plus.circle")
                    }
                    
                    Divider()
                    
                    Button {
                        libraryVM.isSelectionMode = true
                    } label: {
                        Label("Select Files", systemImage: "checkmark.circle")
                    }
                    .disabled(libraryVM.files.isEmpty)
                    
                    Divider()
                    
                    Menu("Sort By") {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button {
                                if libraryVM.sortOption == option {
                                    libraryVM.sortAscending.toggle()
                                } else {
                                    libraryVM.sortOption = option
                                    libraryVM.sortAscending = true
                                }
                            } label: {
                                HStack {
                                    Text(option.rawValue)
                                    if libraryVM.sortOption == option {
                                        Image(systemName: libraryVM.sortAscending ? "chevron.up" : "chevron.down")
                                    }
                                }
                            }
                        }
                    }
                    
                    Button {
                        libraryVM.showingFilterSheet = true
                    } label: {
                        Label("Filters", systemImage: "line.3.horizontal.decrease.circle")
                    }
                    
                    Divider()
                    
                    Button {
                        libraryVM.refreshLibrary()
                    } label: {
                        Label("Refresh Tags", systemImage: "arrow.clockwise")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        
        if libraryVM.isSelectionMode {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Button {
                        libraryVM.selectAll()
                    } label: {
                        Label("Select All", systemImage: "checkmark.circle.fill")
                    }
                    
                    Button {
                        libraryVM.deselectAll()
                    } label: {
                        Label("Deselect All", systemImage: "circle")
                    }
                    
                    Divider()
                    
                    Button {
                        libraryVM.showingBatchEdit = true
                    } label: {
                        Label("Batch Edit", systemImage: "pencil.circle")
                    }
                    .disabled(libraryVM.selectedFiles.isEmpty)
                    
                    Button(role: .destructive) {
                        libraryVM.deleteSelectedFiles()
                    } label: {
                        Label("Delete Selected", systemImage: "trash")
                    }
                    .disabled(libraryVM.selectedFiles.isEmpty)
                } label: {
                    Text("Actions")
                }
            }
        }
    }
    
    // MARK: - Import Handlers
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            libraryVM.importFiles(urls: urls)
        case .failure(let error):
            libraryVM.showError(message: error.localizedDescription)
        }
    }
    
    private func handleFolderImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let folderURL = urls.first {
                libraryVM.importFolder(url: folderURL)
            }
        case .failure(let error):
            libraryVM.showError(message: error.localizedDescription)
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Loading Overlay
struct LoadingOverlay: View {
    let message: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.white)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.white)
            }
            .padding(32)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        }
    }
}

// MARK: - Library Stats View
struct LibraryStatsView: View {
    let statistics: LibraryStatistics
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Overview") {
                    StatRow(label: "Total Files", value: "\(statistics.totalFiles)")
                    StatRow(label: "Total Size", value: statistics.totalSizeFormatted)
                    StatRow(label: "Unique Artists", value: "\(statistics.uniqueArtists)")
                    StatRow(label: "Unique Albums", value: "\(statistics.uniqueAlbums)")
                }
                
                Section("Tag Quality") {
                    StatRow(label: "Average Completeness", value: statistics.completenessPercentage)
                    StatRow(label: "With Album Art", value: "\(statistics.withAlbumArt) of \(statistics.totalFiles)")
                }
            }
            .navigationTitle("Library Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .bold()
        }
    }
}
