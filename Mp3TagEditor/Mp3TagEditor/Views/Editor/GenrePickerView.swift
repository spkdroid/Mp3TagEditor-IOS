import SwiftUI

// MARK: - Genre Picker Field
struct GenrePickerField: View {
    @Binding var genre: String
    @State private var showingGenrePicker = false
    
    var body: some View {
        Button {
            showingGenrePicker = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "guitars.fill")
                    .font(.body)
                    .foregroundStyle(.tint)
                    .frame(width: 28)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Genre")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(genre.isEmpty ? "Select Genre" : genre)
                        .font(.body)
                        .foregroundStyle(genre.isEmpty ? .tertiary : .primary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingGenrePicker) {
            GenrePickerView(selectedGenre: $genre)
        }
    }
}

// MARK: - Genre Picker View
struct GenrePickerView: View {
    @Binding var selectedGenre: String
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedCategory: Int = 0
    
    var filteredGenres: [String] {
        if searchText.isEmpty {
            if selectedCategory == 0 {
                return ID3GenreList.popularGenres
            } else {
                let category = ID3GenreList.categories[selectedCategory]
                return category.genres
            }
        }
        
        return ID3GenreList.genres.filter {
            $0.lowercased().contains(searchText.lowercased())
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom genre input
                HStack {
                    Image(systemName: "pencil")
                        .foregroundStyle(.secondary)
                    TextField("Custom genre...", text: $selectedGenre)
                        .textFieldStyle(.plain)
                    
                    if !selectedGenre.isEmpty {
                        Button {
                            selectedGenre = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Category Tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(ID3GenreList.categories.enumerated()), id: \.offset) { index, category in
                            CategoryChip(
                                name: category.name,
                                isSelected: selectedCategory == index
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedCategory = index
                                }
                                HapticManager.shared.selection()
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 12)
                
                // Genre Grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(filteredGenres, id: \.self) { genre in
                            GenreChip(
                                name: genre,
                                isSelected: selectedGenre == genre
                            ) {
                                if selectedGenre == genre {
                                    selectedGenre = ""
                                } else {
                                    selectedGenre = genre
                                    HapticManager.shared.impact(.light)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .searchable(text: $searchText, prompt: "Search genres...")
            .navigationTitle("Genre")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .bold()
                }
            }
        }
    }
}

// MARK: - Category Chip
struct CategoryChip: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            Text(name)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.quaternary),
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Genre Chip
struct GenreChip: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            Text(name)
                .font(.caption)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(
                    isSelected
                        ? AnyShapeStyle(.tint.opacity(0.2))
                        : AnyShapeStyle(.regularMaterial),
                    in: RoundedRectangle(cornerRadius: 8)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
                )
                .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
        }
        .buttonStyle(.plain)
    }
}
