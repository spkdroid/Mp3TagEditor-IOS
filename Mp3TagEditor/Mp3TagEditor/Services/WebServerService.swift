import Foundation
import Network

final class WebServerService: ObservableObject {
    @Published var isRunning = false
    @Published var serverURL: String?
    @Published var errorMessage: String?
    @Published var uploadedFileURL: URL?
    @Published var uploadedToken = UUID()

    private var listener: NWListener?
    private let queue = DispatchQueue(label: "mp3.webserver.queue")
    private var bufferByConnection: [ObjectIdentifier: Data] = [:]
    private let fileService = FileManagerService.shared

    func startServer() {
        guard !isRunning else { return }

        do {
            let listener = try NWListener(using: .tcp, on: 8080)
            self.listener = listener

            listener.newConnectionHandler = { [weak self] connection in
                self?.handle(connection: connection)
            }

            listener.stateUpdateHandler = { [weak self] state in
                guard let self else { return }
                Task { @MainActor in
                    switch state {
                    case .ready:
                        self.isRunning = true
                        let host = self.localIPAddress() ?? "localhost"
                        self.serverURL = "http://\(host):8080"
                        self.errorMessage = nil
                    case .failed(let error):
                        self.errorMessage = "Server failed: \(error.localizedDescription)"
                        self.isRunning = false
                    default:
                        break
                    }
                }
            }

            listener.start(queue: queue)
        } catch {
            errorMessage = "Unable to start server: \(error.localizedDescription)"
            isRunning = false
        }
    }

    func stopServer() {
        listener?.cancel()
        listener = nil
        bufferByConnection.removeAll()
        isRunning = false
        serverURL = nil
    }

    private func handle(connection: NWConnection) {
        connection.start(queue: queue)
        receive(on: connection)
    }

    private func receive(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1024 * 1024) { [weak self] data, _, isComplete, error in
            guard let self else { return }
            let key = ObjectIdentifier(connection)

            if let data {
                var buffer = self.bufferByConnection[key] ?? Data()
                buffer.append(data)
                self.bufferByConnection[key] = buffer

                if self.isRequestComplete(buffer) {
                    self.process(buffer: buffer, on: connection)
                    self.bufferByConnection[key] = nil
                    return
                }
            }

            if let error {
                Task { @MainActor in
                    self.errorMessage = "Connection error: \(error.localizedDescription)"
                }
                connection.cancel()
                self.bufferByConnection[key] = nil
                return
            }

            if isComplete {
                if let buffer = self.bufferByConnection[key], !buffer.isEmpty {
                    self.process(buffer: buffer, on: connection)
                }
                self.bufferByConnection[key] = nil
                return
            }

            self.receive(on: connection)
        }
    }

    private func isRequestComplete(_ data: Data) -> Bool {
        guard let headerEndOffset = headerEndOffset(in: data),
              let headersText = String(data: data.prefix(headerEndOffset), encoding: .utf8) else {
            return false
        }

        let bodyByteStart = headerEndOffset + 4
        let bodyLength = data.count - bodyByteStart

        if headersText.contains("GET ") { return true }

        if let contentLength = parseContentLength(headersText) {
            return bodyLength >= contentLength
        }

        return false
    }

    private func headerEndOffset(in data: Data) -> Int? {
        data.range(of: Data("\r\n\r\n".utf8))?.lowerBound
    }

    private func parseContentLength(_ headers: String) -> Int? {
        for line in headers.components(separatedBy: "\r\n") {
            let lower = line.lowercased()
            if lower.hasPrefix("content-length:"),
               let value = line.split(separator: ":", maxSplits: 1).last,
               let length = Int(value.trimmingCharacters(in: .whitespaces)) {
                return length
            }
        }
        return nil
    }

    private func process(buffer: Data, on connection: NWConnection) {
        guard let headerEndOffset = headerEndOffset(in: buffer),
              let headersPart = String(data: buffer.prefix(headerEndOffset), encoding: .utf8) else {
            send(response: http(400, "Bad request"), on: connection)
            return
        }

        let bodyStart = headerEndOffset + 4
        let body = buffer.subdata(in: bodyStart..<buffer.count)

        let firstLine = headersPart.components(separatedBy: "\r\n").first ?? ""
        if firstLine.hasPrefix("GET /") {
            send(response: uploadPageResponse(), on: connection)
            return
        }

        if firstLine.hasPrefix("POST /upload") {
            if handleUpload(headers: headersPart, body: body) {
                send(response: http(200, "Upload successful. Return to the app."), on: connection)
            } else {
                send(response: http(400, "Upload failed. Please upload a valid .mp3 file."), on: connection)
            }
            return
        }

        send(response: http(404, "Not found"), on: connection)
    }

    private func handleUpload(headers: String, body: Data) -> Bool {
        guard let boundary = parseBoundary(headers: headers),
              let upload = extractMultipartFile(body: body, boundary: boundary),
              !upload.data.isEmpty else {
            return false
        }

        let ext = upload.filename
            .flatMap { URL(fileURLWithPath: $0).pathExtension.lowercased() }
            .flatMap { $0.isEmpty ? nil : $0 } ?? "mp3"

        guard ext == "mp3" else {
            Task { @MainActor in
                self.errorMessage = "Only MP3 uploads are supported."
            }
            return false
        }

        let baseName = upload.filename
            .map { URL(fileURLWithPath: $0).deletingPathExtension().lastPathComponent }
            .flatMap { $0.isEmpty ? nil : $0 } ?? "Uploaded"

        let safeName = baseName.replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: "\\", with: "-")
        let fileName = "\(safeName).mp3"
        let outputURL = fileService.editedFilesDirectory.appendingPathComponent(fileName)
        let finalURL = uniqueURL(for: outputURL)

        do {
            try upload.data.write(to: finalURL, options: .atomic)
            Task { @MainActor in
                self.uploadedFileURL = finalURL
                self.uploadedToken = UUID()
                self.errorMessage = nil
            }
            return true
        } catch {
            Task { @MainActor in
                self.errorMessage = "Save failed: \(error.localizedDescription)"
            }
            return false
        }
    }

    private func parseBoundary(headers: String) -> String? {
        for line in headers.components(separatedBy: "\r\n") {
            let lower = line.lowercased()
            if lower.hasPrefix("content-type:"), let range = line.range(of: "boundary=") {
                return String(line[range.upperBound...])
                    .trimmingCharacters(in: .whitespaces)
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            }
        }
        return nil
    }

    private func extractMultipartFile(body: Data, boundary: String) -> (data: Data, filename: String?)? {
        let boundaryData = Data("--\(boundary)".utf8)
        let headerSeparator = Data("\r\n\r\n".utf8)
        let partDelimiter = Data("\r\n".utf8)
        let nextBoundaryPrefix = Data("\r\n--\(boundary)".utf8)

        var searchStart = body.startIndex

        while let boundaryRange = body.range(of: boundaryData, in: searchStart..<body.endIndex) {
            let afterBoundary = boundaryRange.upperBound

            if afterBoundary + 1 < body.endIndex,
               body[afterBoundary] == UInt8(ascii: "-"),
               body[afterBoundary + 1] == UInt8(ascii: "-") {
                break
            }

            guard let firstLineEnd = body.range(of: partDelimiter, in: afterBoundary..<body.endIndex),
                  let headersEnd = body.range(of: headerSeparator, in: firstLineEnd.upperBound..<body.endIndex) else {
                break
            }

            let headersData = body.subdata(in: firstLineEnd.upperBound..<headersEnd.lowerBound)
            guard let headersString = String(data: headersData, encoding: .utf8) else {
                searchStart = headersEnd.upperBound
                continue
            }

            let dataStart = headersEnd.upperBound
            guard let nextBoundary = body.range(of: nextBoundaryPrefix, in: dataStart..<body.endIndex) else {
                break
            }

            if headersString.contains("filename=") {
                let fileData = body.subdata(in: dataStart..<nextBoundary.lowerBound)
                let filename = parseFilename(fromPartHeaders: headersString)
                return (fileData, filename)
            }

            searchStart = nextBoundary.lowerBound + 2
        }

        return nil
    }

    private func parseFilename(fromPartHeaders headers: String) -> String? {
        for line in headers.components(separatedBy: "\r\n") {
            let lower = line.lowercased()
            guard lower.hasPrefix("content-disposition:"),
                  let range = line.range(of: "filename=") else { continue }

            var raw = String(line[range.upperBound...]).trimmingCharacters(in: .whitespaces)
            if raw.hasPrefix("\"") {
                raw.removeFirst()
                if let endQuote = raw.firstIndex(of: "\"") {
                    return String(raw[..<endQuote])
                }
            }

            if let semicolon = raw.firstIndex(of: ";") {
                raw = String(raw[..<semicolon])
            }
            return raw.trimmingCharacters(in: .whitespaces)
        }
        return nil
    }

    private func send(response: Data, on connection: NWConnection) {
        connection.send(content: response, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }

    private func http(_ status: Int, _ body: String) -> Data {
        let reason: String
        switch status {
        case 200: reason = "OK"
        case 400: reason = "Bad Request"
        case 404: reason = "Not Found"
        default: reason = "OK"
        }

        let payload = "HTTP/1.1 \(status) \(reason)\r\nContent-Type: text/plain; charset=utf-8\r\nContent-Length: \(body.utf8.count)\r\nConnection: close\r\n\r\n\(body)"
        return Data(payload.utf8)
    }

    private func uploadPageResponse() -> Data {
        let html = """
        <!doctype html>
        <html>
        <head>
          <meta name='viewport' content='width=device-width,initial-scale=1'>
          <title>MP3 Upload</title>
          <style>
            body { font-family: -apple-system, system-ui; max-width: 560px; margin: 40px auto; padding: 0 16px; background: #0d1117; color: #f5f7fa; }
            .card { border: 1px solid #2a2f3a; border-radius: 14px; padding: 18px; background: #161b22; }
            button { padding: 10px 14px; border: 0; border-radius: 10px; background: #0a84ff; color: white; font-weight: 600; }
            input { width: 100%; }
          </style>
        </head>
        <body>
          <div class='card'>
            <h2>Upload MP3 to Mp3TagEditor</h2>
            <form id='form'>
              <input type='file' name='audio' accept='.mp3,audio/mpeg' required />
              <br/><br/>
              <button type='submit'>Upload</button>
            </form>
            <p id='status'></p>
          </div>
          <script>
            const form = document.getElementById('form');
            const status = document.getElementById('status');
            form.addEventListener('submit', async (e) => {
              e.preventDefault();
              const fd = new FormData(form);
              status.textContent = 'Uploading...';
              const res = await fetch('/upload', { method: 'POST', body: fd });
              status.textContent = await res.text();
            });
          </script>
        </body>
        </html>
        """
        let response = "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: \(html.utf8.count)\r\nConnection: close\r\n\r\n\(html)"
        return Data(response.utf8)
    }

    private func uniqueURL(for url: URL) -> URL {
        let fm = FileManager.default
        guard fm.fileExists(atPath: url.path) else { return url }

        let directory = url.deletingLastPathComponent()
        let name = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension

        var counter = 1
        var newURL: URL

        repeat {
            newURL = directory.appendingPathComponent("\(name) (\(counter)).\(ext)")
            counter += 1
        } while fm.fileExists(atPath: newURL.path)

        return newURL
    }

    private func localIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return nil }
        defer { freeifaddrs(ifaddr) }

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                if name == "en0" {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr,
                                socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname,
                                socklen_t(hostname.count),
                                nil,
                                socklen_t(0),
                                NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        return address
    }
}
