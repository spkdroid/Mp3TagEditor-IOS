import SwiftUI

// MARK: - Import Options View
struct ImportOptionsView: View {
    @EnvironmentObject private var libraryVM: LibraryViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(ImportSource.allCases) { source in
                        Button {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                switch source {
                                case .files:
                                    libraryVM.showingImportPicker = true
                                case .folder:
                                    libraryVM.showingFolderPicker = true
                                }
                            }
                        } label: {
                            HStack(spacing: 16) {
                                Image(systemName: source.icon)
                                    .font(.title2)
                                    .foregroundStyle(.tint)
                                    .frame(width: 44)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(source.rawValue)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    
                                    Text(source.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                } header: {
                    Text("Choose Import Source")
                } footer: {
                    Text("MP3 files will be copied to the app's document storage. Original files remain unchanged.")
                }
                
                Section("Supported Formats") {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("MP3 files with ID3v1, ID3v1.1, ID3v2.2, ID3v2.3, ID3v2.4 tags")
                            .font(.subheadline)
                    }
                }
            }
            .navigationTitle("Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Filter Sheet View
struct FilterSheetView: View {
    @EnvironmentObject private var libraryVM: LibraryViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var hasAlbumArt: Bool? = nil
    @State private var selectedGenre: String = ""
    @State private var selectedYear: String = ""
    @State private var minCompleteness: Double = 0
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Album Art") {
                    Picker("Album Art", selection: $hasAlbumArt) {
                        Text("Any").tag(nil as Bool?)
                        Text("Has Artwork").tag(true as Bool?)
                        Text("Missing Artwork").tag(false as Bool?)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Genre") {
                    Picker("Genre", selection: $selectedGenre) {
                        Text("All Genres").tag("")
                        ForEach(libraryVM.uniqueGenres, id: \.self) { genre in
                            Text(genre).tag(genre)
                        }
                    }
                }
                
                Section("Year") {
                    Picker("Year", selection: $selectedYear) {
                        Text("All Years").tag("")
                        ForEach(libraryVM.uniqueYears, id: \.self) { year in
                            Text(year).tag(year)
                        }
                    }
                }
                
                Section("Tag Completeness") {
                    VStack(alignment: .leading) {
                        Text("Minimum: \(Int(minCompleteness * 100))%")
                            .font(.subheadline)
                        Slider(value: $minCompleteness, in: 0...1, step: 0.1)
                    }
                }
                
                Section {
                    Button("Clear All Filters", role: .destructive) {
                        hasAlbumArt = nil
                        selectedGenre = ""
                        selectedYear = ""
                        minCompleteness = 0
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Apply") {
                        libraryVM.filterOptions = FilterOptions(
                            hasAlbumArt: hasAlbumArt,
                            minCompleteness: minCompleteness > 0 ? minCompleteness : nil,
                            genre: selectedGenre.isEmpty ? nil : selectedGenre,
                            year: selectedYear.isEmpty ? nil : selectedYear
                        )
                        dismiss()
                    }
                    .bold()
                }
            }
            .onAppear {
                hasAlbumArt = libraryVM.filterOptions.hasAlbumArt
                selectedGenre = libraryVM.filterOptions.genre ?? ""
                selectedYear = libraryVM.filterOptions.year ?? ""
                minCompleteness = libraryVM.filterOptions.minCompleteness ?? 0
            }
        }
        .presentationDetents([.medium, .large])
    }
}
