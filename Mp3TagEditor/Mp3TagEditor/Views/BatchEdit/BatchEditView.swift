import SwiftUI
import PhotosUI

// MARK: - Batch Edit View
struct BatchEditView: View {
    @EnvironmentObject private var libraryVM: LibraryViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var operations: [BatchEditOperation] = []
    @State private var showingAddField = false
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    
    // Album art batch
    @State private var applyAlbumArt = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var albumArtData: Data?
    @State private var albumArtImage: UIImage?
    
    var selectedFiles: [MP3File] {
        libraryVM.files.filter { libraryVM.selectedFiles.contains($0.id) }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Selected Files Summary
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.tint)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(selectedFiles.count) files selected")
                                .font(.headline)
                            Text("Changes will apply to all selected files")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // Field Operations
                Section("Tag Fields") {
                    ForEach($operations) { $operation in
                        BatchFieldRow(operation: $operation) {
                            operations.removeAll { $0.id == operation.id }
                        }
                    }
                    
                    Button {
                        showingAddField = true
                    } label: {
                        Label("Add Field", systemImage: "plus.circle.fill")
                    }
                }
                
                // Album Art
                Section("Album Artwork") {
                    Toggle("Apply Album Art", isOn: $applyAlbumArt)
                    
                    if applyAlbumArt {
                        HStack {
                            if let image = albumArtImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            } else {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.quaternary)
                                    .frame(width: 60, height: 60)
                                    .overlay {
                                        Image(systemName: "photo")
                                            .foregroundStyle(.secondary)
                                    }
                            }
                            
                            PhotosPicker(selection: $selectedPhotoItem,
                                        matching: .images) {
                                Text(albumArtImage != nil ? "Change Image" : "Select Image")
                            }
                        }
                        .onChange(of: selectedPhotoItem) {
                            Task { await loadAlbumArt() }
                        }
                    }
                }
                
                // Preview
                if !operations.isEmpty || applyAlbumArt {
                    Section("Preview") {
                        ForEach(selectedFiles.prefix(5)) { file in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(file.displayTitle)
                                    .font(.subheadline.weight(.medium))
                                Text(file.displayArtist)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        if selectedFiles.count > 5 {
                            Text("... and \(selectedFiles.count - 5) more")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Batch Edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Apply") {
                        applyChanges()
                    }
                    .bold()
                    .disabled(operations.isEmpty && !applyAlbumArt)
                }
            }
            .sheet(isPresented: $showingAddField) {
                AddFieldSheet(operations: $operations)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if showSuccess {
                    successOverlay
                }
                if isSaving {
                    LoadingOverlay(message: "Applying changes...")
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func applyChanges() {
        isSaving = true
        
        Task {
            do {
                // Apply text field operations
                if !operations.isEmpty {
                    try libraryVM.applyBatchEdit(
                        operations: operations,
                        to: libraryVM.selectedFiles
                    )
                }
                
                // Apply album art
                if applyAlbumArt, let artData = albumArtData {
                    try libraryVM.applyAlbumArtToSelected(imageData: artData)
                }
                
                isSaving = false
                showSuccess = true
                HapticManager.shared.notification(.success)
                
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                dismiss()
            } catch {
                isSaving = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    private func loadAlbumArt() async {
        guard let item = selectedPhotoItem else { return }
        
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            let resized = ImageService.squareThumbnail(from: image, size: 600)
            albumArtData = ImageService.compress(image: resized, maxSizeKB: 500)
            albumArtImage = resized
        }
    }
    
    private var successOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)
            
            Text("Changes Applied!")
                .font(.headline)
            
            Text("\(selectedFiles.count) files updated")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(40)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Batch Field Row
struct BatchFieldRow: View {
    @Binding var operation: BatchEditOperation
    let onDelete: () -> Void
    @State private var showingGenrePicker = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: operation.field.icon)
                .foregroundStyle(.tint)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(operation.field.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if operation.field == .genre {
                    Button {
                        showingGenrePicker = true
                    } label: {
                        Text(operation.value.isEmpty ? "Select Genre" : operation.value)
                            .foregroundStyle(operation.value.isEmpty ? .tertiary : .primary)
                    }
                    .sheet(isPresented: $showingGenrePicker) {
                        GenrePickerView(selectedGenre: $operation.value)
                    }
                } else {
                    TextField(operation.field.rawValue, text: $operation.value)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $operation.enabled)
                .labelsHidden()
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Add Field Sheet
struct AddFieldSheet: View {
    @Binding var operations: [BatchEditOperation]
    @Environment(\.dismiss) private var dismiss
    
    var availableFields: [BatchEditField] {
        let usedFields = Set(operations.map { $0.field })
        return BatchEditField.allCases.filter { !usedFields.contains($0) }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(availableFields) { field in
                    Button {
                        operations.append(BatchEditOperation(field: field, value: ""))
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: field.icon)
                                .foregroundStyle(.tint)
                                .frame(width: 28)
                            
                            Text(field.rawValue)
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
            .navigationTitle("Add Field")
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
