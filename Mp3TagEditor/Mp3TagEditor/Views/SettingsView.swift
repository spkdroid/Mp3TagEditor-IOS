import SwiftUI

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
