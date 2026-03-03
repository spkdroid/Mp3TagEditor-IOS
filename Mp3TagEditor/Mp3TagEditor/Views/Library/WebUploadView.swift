import SwiftUI

struct WebUploadView: View {
    @EnvironmentObject private var libraryVM: LibraryViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var server = WebServerService()

    var body: some View {
        NavigationStack {
            List {
                Section("Server") {
                    Toggle("Enable Wi-Fi Upload", isOn: Binding(
                        get: { server.isRunning },
                        set: { isOn in
                            if isOn { server.startServer() } else { server.stopServer() }
                        }
                    ))

                    if let url = server.serverURL {
                        LabeledContent("URL") {
                            Text(url)
                                .font(.footnote.monospaced())
                                .multilineTextAlignment(.trailing)
                                .textSelection(.enabled)
                        }

                        Button {
                            UIPasteboard.general.string = url
                        } label: {
                            Label("Copy URL", systemImage: "doc.on.doc")
                        }
                    }
                }

                Section("How to Upload") {
                    Label("Connect phone and browser device to the same Wi-Fi", systemImage: "wifi")
                    Label("Open the URL above in any browser", systemImage: "safari")
                    Label("Choose an .mp3 file and upload", systemImage: "square.and.arrow.up")
                    Label("Uploaded file is saved to Edited MP3 Files", systemImage: "folder.badge.checkmark")
                }

                if let error = server.errorMessage {
                    Section("Server Message") {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle("Wi-Fi Upload")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        server.stopServer()
                        dismiss()
                    }
                }
            }
            .onChange(of: server.uploadedToken) {
                guard let fileURL = server.uploadedFileURL else { return }
                libraryVM.importManagedFile(at: fileURL)
            }
            .onDisappear {
                server.stopServer()
            }
        }
    }
}
