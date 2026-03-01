# MP3 Tag Editor for iOS

A professional, feature-rich iOS application for editing MP3 ID3 tag metadata directly on your iPhone or iPad.

## Features

### Core Functionality
- **Full ID3 Tag Editing** — Edit all standard metadata fields:
  - Title, Artist, Album, Album Artist
  - Year, Genre, Track Number, Disc Number
  - Composer, BPM, Publisher, Copyright
  - ISRC, Encoder, Original Artist
  - Comments and Lyrics (multiline)
- **Album Artwork** — View, add, replace, or remove album art from your photo library
- **ID3 Tag Support** — Reads ID3v1, ID3v1.1, ID3v2.2, ID3v2.3, ID3v2.4; writes ID3v2.3
- **Custom ID3 Parser** — Zero external dependencies, pure Swift implementation

### Library Management
- **Import from Files** — Import individual MP3 files or entire folders via the iOS Files picker
- **Search** — Full-text search across title, artist, album, genre, and filename
- **Sort** — Sort by title, artist, album, year, date added, or file size (ascending/descending)
- **Filter** — Filter by album art presence, genre, year, or tag completeness
- **Tag Completeness** — Visual indicator showing how complete each file's metadata is
- **Pull to Refresh** — Re-read tags from disk for all files
- **Swipe Actions** — Quick delete or play with swipe gestures

### Batch Editing
- **Multi-Select** — Select multiple files for batch operations
- **Batch Tag Edit** — Apply the same artist, album, genre, year, etc. to multiple files at once
- **Batch Album Art** — Apply the same album artwork to all selected files

### Audio Preview
- **Mini Player** — Floating mini player with play/pause and progress display
- **Full Player** — Expanded player view with seek controls, skip forward/backward
- **Background Playback** — Audio continues playing while editing tags

### User Experience
- **Modern SwiftUI** — Built entirely with SwiftUI targeting iOS 17+
- **Dark Mode** — Full dark mode support with system-adaptive theming
- **Accent Colors** — Choose from 6 accent colors to personalize the app
- **Haptic Feedback** — Tactile feedback throughout the interface (configurable)
- **Shake to Undo** — Shake device to trigger undo
- **Edit History** — Track all tag changes with full edit history
- **Recently Edited** — Quick access to recently modified files
- **Auto-Save** — Optional auto-save for tag changes

### Genre Picker
- **150+ Genres** — Complete ID3v1 genre list plus modern additions
- **Categorized Browsing** — Genres organized by category (Rock, Electronic, Hip-Hop, etc.)
- **Quick Search** — Search across all genres
- **Custom Genres** — Enter any custom genre text

## Architecture

```
Mp3TagEditor/
├── App/
│   ├── Mp3TagEditorApp.swift      # App entry point, AppState
│   └── ContentView.swift          # Tab navigation, Settings
├── Models/
│   ├── MP3File.swift              # File model, EditHistory, BatchEdit models
│   └── Genre.swift                # ID3 genre list with categories
├── Services/
│   ├── ID3Parser.swift            # Complete ID3 tag reader/writer
│   ├── FileManagerService.swift   # File import, persistence, bookmarks
│   ├── AudioPlayerService.swift   # AVAudioPlayer wrapper
│   └── HapticAndImageServices.swift # Haptics + image processing
├── ViewModels/
│   ├── LibraryViewModel.swift     # Library state, search, sort, filter
│   └── TagEditorViewModel.swift   # Tag editing state, save/reset
├── Views/
│   ├── Library/
│   │   ├── LibraryView.swift      # Main library with stats, toolbar
│   │   ├── MP3FileRow.swift       # File row + completeness ring
│   │   └── ImportOptionsView.swift # Import sheet + filter sheet
│   ├── Editor/
│   │   ├── TagEditorView.swift    # Full tag editor with all fields
│   │   └── GenrePickerView.swift  # Categorized genre browser
│   ├── Player/
│   │   └── MiniPlayerView.swift   # Mini + full player views
│   └── BatchEdit/
│       └── BatchEditView.swift    # Multi-file batch editor
├── Extensions/
│   └── Extensions.swift           # Color, View, String, Data extensions
└── Assets.xcassets/               # App icon, accent color
```

**Design Pattern:** MVVM (Model-View-ViewModel)
**UI Framework:** SwiftUI
**Minimum iOS Version:** 17.0
**Swift Version:** 5.0
**Concurrency:** Swift Strict Concurrency (complete)

## Requirements

- Xcode 15.4+
- iOS 17.0+
- Swift 5.0+

## Getting Started

1. Open `Mp3TagEditor.xcodeproj` in Xcode
2. Select your development team under Signing & Capabilities
3. Build and run on a device or simulator
4. Import MP3 files using the "+" button or the Import sheet
5. Tap any file to edit its tags

## Permissions

- **Photo Library** — Required for selecting album artwork images
- **Files Access** — Required for importing MP3 files from the Files app

## How It Works

### ID3 Tag Parsing
The app includes a custom-built ID3 tag parser that handles:
- **ID3v1** — Reads tags from the last 128 bytes of the file
- **ID3v1.1** — Extended v1 format with track number support
- **ID3v2.2/2.3/2.4** — Full frame-based tag parsing including:
  - Text frames (all standard T-frames)
  - Comment/Lyrics frames (COMM, USLT) with language codes
  - Attached picture frames (APIC) with MIME type detection
  - Syncsafe integer encoding/decoding
  - Extended header handling

### Tag Writing
Tags are written in ID3v2.3 format with:
- UTF-8 text encoding for universal character support
- Proper frame headers with size calculations
- 2KB padding for future in-place edits
- Existing tag replacement (removes old ID3v1 + ID3v2 before writing)

## License

This project is provided as-is for educational and personal use.
