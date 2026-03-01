import SwiftUI
import PhotosUI

// MARK: - Tag Editor View
struct TagEditorView: View {
    let file: MP3File
    @StateObject private var viewModel: TagEditorViewModel
    @EnvironmentObject private var libraryVM: LibraryViewModel
    @EnvironmentObject private var playerService: AudioPlayerService
    @Environment(\.dismiss) private var dismiss
    
    init(file: MP3File) {
        self.file = file
        _viewModel = StateObject(wrappedValue: TagEditorViewModel(file: file))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Album Art Section
                albumArtSection
                
                // Playback Controls
                playbackSection
                
                // Primary Fields
                primaryFieldsSection
                
                // Additional Fields
                additionalFieldsSection
                
                // Advanced Fields
                advancedFieldsSection
                
                // File Info
                fileInfoSection
                
                // Actions
                actionsSection
                
                // Spacer for mini player
                if playerService.currentFile != nil {
                    Spacer().frame(height: 80)
                }
            }
            .padding()
        }
        .navigationTitle("Edit Tags")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { editorToolbar }
        .onChange(of: viewModel.title) { viewModel.checkForChanges() }
        .onChange(of: viewModel.artist) { viewModel.checkForChanges() }
        .onChange(of: viewModel.album) { viewModel.checkForChanges() }
        .onChange(of: viewModel.year) { viewModel.checkForChanges() }
        .onChange(of: viewModel.genre) { viewModel.checkForChanges() }
        .onChange(of: viewModel.trackNumber) { viewModel.checkForChanges() }
        .onChange(of: viewModel.discNumber) { viewModel.checkForChanges() }
        .onChange(of: viewModel.composer) { viewModel.checkForChanges() }
        .onChange(of: viewModel.albumArtist) { viewModel.checkForChanges() }
        .onChange(of: viewModel.comment) { viewModel.checkForChanges() }
        .onChange(of: viewModel.lyrics) { viewModel.checkForChanges() }
        .onChange(of: viewModel.bpm) { viewModel.checkForChanges() }
        .onChange(of: viewModel.selectedPhotoItem) {
            Task { await viewModel.handlePhotoSelection() }
        }
        .alert("Save Failed", isPresented: $viewModel.showSaveError) {
            Button("OK") { }
        } message: {
            Text(viewModel.saveError ?? "Unknown error")
        }
        .alert("Discard Changes?", isPresented: $viewModel.showingDiscardAlert) {
            Button("Discard", role: .destructive) { dismiss() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("You have unsaved changes. Are you sure you want to discard them?")
        }
        .overlay(alignment: .bottom) {
            if viewModel.showSaveSuccess {
                saveSuccessBanner
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.showSaveSuccess)
        .interactiveDismissDisabled(viewModel.hasChanges)
    }
    
    // MARK: - Album Art Section
    
    private var albumArtSection: some View {
        VStack(spacing: 12) {
            // Album Art Display
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if let image = viewModel.albumArtImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        ZStack {
                            LinearGradient(
                                colors: [.blue.opacity(0.3), .purple.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            
                            VStack(spacing: 8) {
                                Image(systemName: "music.note")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.secondary)
                                Text("No Album Art")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .frame(width: 220, height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                
                // Edit Button
                Button {
                    viewModel.showingArtOptions = true
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .tint)
                        .shadow(radius: 2)
                }
                .offset(x: 6, y: 6)
            }
            
            // File name
            Text(file.fileName)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
            
            // Tag version badge
            Text(viewModel.tagVersion)
                .font(.caption2.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(.tint.opacity(0.15), in: Capsule())
                .foregroundStyle(.tint)
        }
        .confirmationDialog("Album Artwork", isPresented: $viewModel.showingArtOptions) {
            PhotosPicker(selection: $viewModel.selectedPhotoItem,
                        matching: .images) {
                Text("Choose from Photos")
            }
            
            if viewModel.albumArtImage != nil {
                Button("Remove Artwork", role: .destructive) {
                    viewModel.removeAlbumArt()
                }
            }
        }
    }
    
    // MARK: - Playback Section
    
    private var playbackSection: some View {
        HStack(spacing: 16) {
            Button {
                if playerService.currentFile?.id == file.id {
                    playerService.togglePlayPause()
                } else {
                    playerService.play(file: file)
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: playerService.currentFile?.id == file.id && playerService.isPlaying
                          ? "pause.fill" : "play.fill")
                    Text(playerService.currentFile?.id == file.id && playerService.isPlaying
                         ? "Pause" : "Preview")
                }
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .buttonStyle(.bordered)
            .tint(.blue)
        }
    }
    
    // MARK: - Primary Fields
    
    private var primaryFieldsSection: some View {
        VStack(spacing: 2) {
            SectionHeader(title: "Basic Information", icon: "music.note")
            
            VStack(spacing: 0) {
                TagTextField(label: "Title", text: $viewModel.title, icon: "textformat")
                Divider().padding(.leading, 44)
                TagTextField(label: "Artist", text: $viewModel.artist, icon: "person.fill")
                Divider().padding(.leading, 44)
                TagTextField(label: "Album", text: $viewModel.album, icon: "square.stack.fill")
                Divider().padding(.leading, 44)
                TagTextField(label: "Album Artist", text: $viewModel.albumArtist, icon: "person.2.fill")
            }
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Additional Fields
    
    private var additionalFieldsSection: some View {
        VStack(spacing: 2) {
            SectionHeader(title: "Details", icon: "info.circle")
            
            VStack(spacing: 0) {
                // Genre with picker
                GenrePickerField(genre: $viewModel.genre)
                
                Divider().padding(.leading, 44)
                TagTextField(label: "Year", text: $viewModel.year, icon: "calendar",
                            keyboardType: .numberPad)
                Divider().padding(.leading, 44)
                TagTextField(label: "Track #", text: $viewModel.trackNumber, icon: "number",
                            keyboardType: .numberPad)
                Divider().padding(.leading, 44)
                TagTextField(label: "Disc #", text: $viewModel.discNumber, icon: "opticaldisc",
                            keyboardType: .numberPad)
                Divider().padding(.leading, 44)
                TagTextField(label: "Composer", text: $viewModel.composer, icon: "music.quarternote.3")
                Divider().padding(.leading, 44)
                TagTextField(label: "BPM", text: $viewModel.bpm, icon: "metronome.fill",
                            keyboardType: .numberPad)
            }
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Advanced Fields
    
    private var advancedFieldsSection: some View {
        VStack(spacing: 2) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    viewModel.showingAdvancedFields.toggle()
                }
            } label: {
                HStack {
                    SectionHeader(title: "Advanced", icon: "slider.horizontal.3")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(viewModel.showingAdvancedFields ? 90 : 0))
                }
            }
            .buttonStyle(.plain)
            
            if viewModel.showingAdvancedFields {
                VStack(spacing: 0) {
                    TagTextField(label: "Publisher", text: $viewModel.publisher, icon: "building.2.fill")
                    Divider().padding(.leading, 44)
                    TagTextField(label: "Copyright", text: $viewModel.copyright, icon: "c.circle.fill")
                    Divider().padding(.leading, 44)
                    TagTextField(label: "Encoder", text: $viewModel.encoder, icon: "cpu")
                    Divider().padding(.leading, 44)
                    TagTextField(label: "ISRC", text: $viewModel.isrc, icon: "barcode")
                    Divider().padding(.leading, 44)
                    TagTextField(label: "Original Artist", text: $viewModel.originalArtist, icon: "person.fill.questionmark")
                    Divider().padding(.leading, 44)
                    
                    // Comment (multiline)
                    TagTextEditor(label: "Comment", text: $viewModel.comment, icon: "text.bubble.fill")
                    Divider().padding(.leading, 44)
                    
                    // Lyrics (multiline)
                    TagTextEditor(label: "Lyrics", text: $viewModel.lyrics, icon: "text.quote")
                }
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    // MARK: - File Info
    
    private var fileInfoSection: some View {
        VStack(spacing: 2) {
            SectionHeader(title: "File Information", icon: "doc.fill")
            
            VStack(spacing: 8) {
                InfoRow(label: "File Name", value: file.fileName)
                InfoRow(label: "File Size", value: file.fileSizeFormatted)
                InfoRow(label: "Tag Version", value: file.tag.version.rawValue)
                InfoRow(label: "Last Modified", value: file.dateModified.formatted(date: .abbreviated, time: .shortened))
            }
            .padding(14)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Actions
    
    private var actionsSection: some View {
        VStack(spacing: 10) {
            // Save Button
            Button {
                viewModel.save(using: libraryVM)
            } label: {
                HStack {
                    if viewModel.isSaving {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                    }
                    Text(viewModel.isSaving ? "Saving..." : "Save Changes")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.hasChanges || viewModel.isSaving)
            
            // Secondary Actions
            HStack(spacing: 10) {
                Button {
                    viewModel.resetToOriginal()
                } label: {
                    HStack {
                        Image(systemName: "arrow.uturn.backward")
                        Text("Reset")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.bordered)
                .disabled(!viewModel.hasChanges)
                
                Button(role: .destructive) {
                    viewModel.clearAllFields()
                } label: {
                    HStack {
                        Image(systemName: "xmark.circle")
                        Text("Clear All")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.bordered)
            }
            .font(.subheadline)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Save Success Banner
    
    private var saveSuccessBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text("Tags saved successfully!")
                .font(.subheadline.weight(.medium))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        .padding(.bottom, 16)
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var editorToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if viewModel.hasChanges {
                Button {
                    viewModel.save(using: libraryVM)
                } label: {
                    Text("Save")
                        .bold()
                }
            }
        }
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.tint)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
        .padding(.bottom, 4)
    }
}

// MARK: - Tag Text Field
struct TagTextField: View {
    let label: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.tint)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                TextField(label, text: $text)
                    .font(.body)
                    .keyboardType(keyboardType)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

// MARK: - Tag Text Editor (Multiline)
struct TagTextEditor: View {
    let label: String
    @Binding var text: String
    let icon: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.tint)
                .frame(width: 28)
                .padding(.top, 10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                TextEditor(text: $text)
                    .font(.body)
                    .frame(minHeight: 60, maxHeight: 120)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, -4)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .lineLimit(1)
        }
    }
}
