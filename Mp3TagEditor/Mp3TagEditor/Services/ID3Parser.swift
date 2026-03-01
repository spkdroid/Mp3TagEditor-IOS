import Foundation

// MARK: - ID3 Tag Version
enum ID3Version: String, Codable {
    case v1 = "ID3v1"
    case v1_1 = "ID3v1.1"
    case v2_2 = "ID3v2.2"
    case v2_3 = "ID3v2.3"
    case v2_4 = "ID3v2.4"
    case none = "None"
}

// MARK: - ID3 Frame IDs
enum ID3FrameID: String {
    // ID3v2.3/v2.4 frame IDs
    case title = "TIT2"
    case artist = "TPE1"
    case album = "TALB"
    case year = "TYER"          // v2.3
    case recordingDate = "TDRC"  // v2.4
    case genre = "TCON"
    case trackNumber = "TRCK"
    case discNumber = "TPOS"
    case composer = "TCOM"
    case albumArtist = "TPE2"
    case comment = "COMM"
    case lyrics = "USLT"
    case bpm = "TBPM"
    case attachedPicture = "APIC"
    case encoder = "TENC"
    case copyright = "TCOP"
    case publisher = "TPUB"
    case originalArtist = "TOPE"
    case url = "WXXX"
    case isrc = "TSRC"
    case compilation = "TCMP"
    
    // ID3v2.2 equivalents
    var v22Equivalent: String {
        switch self {
        case .title: return "TT2"
        case .artist: return "TP1"
        case .album: return "TAL"
        case .year: return "TYE"
        case .genre: return "TCO"
        case .trackNumber: return "TRK"
        case .discNumber: return "TPA"
        case .composer: return "TCM"
        case .albumArtist: return "TP2"
        case .comment: return "COM"
        case .lyrics: return "ULT"
        case .bpm: return "TBP"
        case .attachedPicture: return "PIC"
        case .encoder: return "TEN"
        case .copyright: return "TCR"
        case .publisher: return "TPB"
        case .originalArtist: return "TOA"
        case .url: return "WXX"
        case .isrc: return "TRC"
        case .compilation: return "TCP"
        case .recordingDate: return "TYE"
        }
    }
    
    static func from(v22FrameID: String) -> ID3FrameID? {
        for frame in [title, artist, album, year, genre, trackNumber, discNumber,
                      composer, albumArtist, comment, lyrics, bpm, attachedPicture,
                      encoder, copyright, publisher, originalArtist, url, isrc, compilation] {
            if frame.v22Equivalent == v22FrameID {
                return frame
            }
        }
        return nil
    }
}

// MARK: - Picture Type
enum ID3PictureType: UInt8 {
    case other = 0x00
    case fileIcon = 0x01
    case otherFileIcon = 0x02
    case frontCover = 0x03
    case backCover = 0x04
    case leafletPage = 0x05
    case media = 0x06
    case leadArtist = 0x07
    case artist = 0x08
    case conductor = 0x09
    case band = 0x0A
    case composer = 0x0B
    case lyricist = 0x0C
    case recordingLocation = 0x0D
    case duringRecording = 0x0E
    case duringPerformance = 0x0F
    case movieCapture = 0x10
    case illustration = 0x11
    case bandLogo = 0x12
    case publisherLogo = 0x13
}

// MARK: - Text Encoding
enum ID3TextEncoding: UInt8 {
    case iso88591 = 0x00
    case utf16WithBOM = 0x01
    case utf16BigEndian = 0x02
    case utf8 = 0x03
    
    var encoding: String.Encoding {
        switch self {
        case .iso88591: return .isoLatin1
        case .utf16WithBOM: return .utf16
        case .utf16BigEndian: return .utf16BigEndian
        case .utf8: return .utf8
        }
    }
    
    var terminatorSize: Int {
        switch self {
        case .iso88591, .utf8: return 1
        case .utf16WithBOM, .utf16BigEndian: return 2
        }
    }
}

// MARK: - ID3 Tag Data
struct ID3Tag: Codable, Equatable {
    var title: String?
    var artist: String?
    var album: String?
    var year: String?
    var genre: String?
    var trackNumber: String?
    var discNumber: String?
    var composer: String?
    var albumArtist: String?
    var comment: String?
    var lyrics: String?
    var bpm: String?
    var encoder: String?
    var copyright: String?
    var publisher: String?
    var originalArtist: String?
    var isrc: String?
    
    var albumArtData: Data?
    var albumArtMimeType: String?
    
    var version: ID3Version = .none
    var originalSize: Int = 0
    
    var hasAlbumArt: Bool {
        albumArtData != nil && !(albumArtData?.isEmpty ?? true)
    }
    
    var displayTitle: String {
        title ?? "Unknown Title"
    }
    
    var displayArtist: String {
        artist ?? "Unknown Artist"
    }
    
    var displayAlbum: String {
        album ?? "Unknown Album"
    }
    
    var isEmpty: Bool {
        title == nil && artist == nil && album == nil && year == nil && genre == nil
    }
    
    static let empty = ID3Tag()
}

// MARK: - ID3 Parser
final class ID3Parser {
    
    // MARK: - Reading
    
    static func parse(data: Data) -> ID3Tag {
        var tag = ID3Tag()
        
        // Try ID3v2 first (at the beginning of the file)
        if data.count > 10, parseID3v2Header(data: data, tag: &tag) {
            // Successfully parsed ID3v2
        }
        
        // Also check for ID3v1 at the end
        if data.count > 128 {
            parseID3v1(data: data, tag: &tag)
        }
        
        return tag
    }
    
    static func parse(url: URL) throws -> ID3Tag {
        let data = try Data(contentsOf: url)
        return parse(data: data)
    }
    
    // MARK: - ID3v1 Parsing
    
    private static func parseID3v1(data: Data, tag: inout ID3Tag) {
        let tagStart = data.count - 128
        guard tagStart >= 0 else { return }
        
        let tagData = data.subdata(in: tagStart..<data.count)
        
        // Check for "TAG" identifier
        guard tagData.count >= 128,
              String(data: tagData[0..<3], encoding: .ascii) == "TAG" else {
            return
        }
        
        // Only use ID3v1 data if ID3v2 didn't provide values
        let v1Title = readFixedString(tagData, offset: 3, length: 30)
        let v1Artist = readFixedString(tagData, offset: 33, length: 30)
        let v1Album = readFixedString(tagData, offset: 63, length: 30)
        let v1Year = readFixedString(tagData, offset: 93, length: 4)
        let v1Comment = readFixedString(tagData, offset: 97, length: 30)
        let genreByte = tagData[127]
        
        if tag.title == nil { tag.title = v1Title }
        if tag.artist == nil { tag.artist = v1Artist }
        if tag.album == nil { tag.album = v1Album }
        if tag.year == nil { tag.year = v1Year }
        if tag.comment == nil { tag.comment = v1Comment }
        
        if tag.genre == nil, genreByte < ID3GenreList.genres.count {
            tag.genre = ID3GenreList.genres[Int(genreByte)]
        }
        
        // Check for ID3v1.1 (track number in comment field)
        if tagData[125] == 0 && tagData[126] != 0 {
            if tag.trackNumber == nil {
                tag.trackNumber = String(tagData[126])
            }
            if tag.version == .none {
                tag.version = .v1_1
            }
        } else if tag.version == .none {
            tag.version = .v1
        }
    }
    
    // MARK: - ID3v2 Parsing
    
    private static func parseID3v2Header(data: Data, tag: inout ID3Tag) -> Bool {
        guard data.count > 10 else { return false }
        
        // Check "ID3" magic bytes
        guard data[0] == 0x49, data[1] == 0x44, data[2] == 0x33 else { return false }
        
        let majorVersion = data[3]
        let minorVersion = data[4]
        let flags = data[5]
        
        // Parse size (syncsafe integer)
        let size = syncsafeToInt(data[6], data[7], data[8], data[9])
        
        tag.originalSize = size + 10
        
        switch majorVersion {
        case 2: tag.version = .v2_2
        case 3: tag.version = .v2_3
        case 4: tag.version = .v2_4
        default: return false
        }
        
        _ = minorVersion
        
        let hasExtendedHeader = (flags & 0x40) != 0
        var offset = 10
        
        // Skip extended header if present
        if hasExtendedHeader && offset + 4 <= data.count {
            let extSize: Int
            if majorVersion == 4 {
                extSize = syncsafeToInt(data[offset], data[offset + 1], data[offset + 2], data[offset + 3])
            } else {
                extSize = Int(data[offset]) << 24 | Int(data[offset + 1]) << 16 |
                          Int(data[offset + 2]) << 8 | Int(data[offset + 3])
            }
            offset += extSize
        }
        
        let tagEnd = min(10 + size, data.count)
        let frameHeaderSize = majorVersion == 2 ? 6 : 10
        let frameIDSize = majorVersion == 2 ? 3 : 4
        
        // Parse frames
        while offset + frameHeaderSize <= tagEnd {
            // Check for padding
            if data[offset] == 0x00 { break }
            
            let frameIDData = data[offset..<(offset + frameIDSize)]
            guard let frameIDStr = String(data: frameIDData, encoding: .ascii),
                  !frameIDStr.isEmpty else { break }
            
            let frameSize: Int
            if majorVersion == 2 {
                frameSize = Int(data[offset + 3]) << 16 | Int(data[offset + 4]) << 8 | Int(data[offset + 5])
            } else if majorVersion == 4 {
                frameSize = syncsafeToInt(data[offset + 4], data[offset + 5], data[offset + 6], data[offset + 7])
            } else {
                frameSize = Int(data[offset + 4]) << 24 | Int(data[offset + 5]) << 16 |
                            Int(data[offset + 6]) << 8 | Int(data[offset + 7])
            }
            
            guard frameSize > 0, offset + frameHeaderSize + frameSize <= tagEnd else { break }
            
            let frameData = data[(offset + frameHeaderSize)..<(offset + frameHeaderSize + frameSize)]
            
            // Map frame ID to our enum
            let frameID: ID3FrameID?
            if majorVersion == 2 {
                frameID = ID3FrameID.from(v22FrameID: frameIDStr)
            } else {
                frameID = ID3FrameID(rawValue: frameIDStr)
            }
            
            if let frameID = frameID {
                parseFrame(id: frameID, data: Data(frameData), version: majorVersion, tag: &tag)
            }
            
            offset += frameHeaderSize + frameSize
        }
        
        return true
    }
    
    private static func parseFrame(id: ID3FrameID, data: Data, version: UInt8, tag: inout ID3Tag) {
        switch id {
        case .title:
            tag.title = readTextFrame(data)
        case .artist:
            tag.artist = readTextFrame(data)
        case .album:
            tag.album = readTextFrame(data)
        case .year, .recordingDate:
            tag.year = readTextFrame(data)
        case .genre:
            tag.genre = parseGenreString(readTextFrame(data) ?? "")
        case .trackNumber:
            tag.trackNumber = readTextFrame(data)
        case .discNumber:
            tag.discNumber = readTextFrame(data)
        case .composer:
            tag.composer = readTextFrame(data)
        case .albumArtist:
            tag.albumArtist = readTextFrame(data)
        case .bpm:
            tag.bpm = readTextFrame(data)
        case .encoder:
            tag.encoder = readTextFrame(data)
        case .copyright:
            tag.copyright = readTextFrame(data)
        case .publisher:
            tag.publisher = readTextFrame(data)
        case .originalArtist:
            tag.originalArtist = readTextFrame(data)
        case .isrc:
            tag.isrc = readTextFrame(data)
        case .comment:
            tag.comment = readCommentFrame(data)
        case .lyrics:
            tag.lyrics = readCommentFrame(data)
        case .attachedPicture:
            parsePictureFrame(data: data, version: version, tag: &tag)
        default:
            break
        }
    }
    
    // MARK: - Frame Reading Helpers
    
    private static func readTextFrame(_ data: Data) -> String? {
        guard data.count > 1 else { return nil }
        
        let encoding = ID3TextEncoding(rawValue: data[0]) ?? .iso88591
        let textData = data[1...]
        
        return decodeString(data: Data(textData), encoding: encoding)
    }
    
    private static func readCommentFrame(_ data: Data) -> String? {
        guard data.count > 4 else { return nil }
        
        let encoding = ID3TextEncoding(rawValue: data[0]) ?? .iso88591
        // Skip language code (3 bytes) and short description (null-terminated)
        var offset = 4
        
        // Skip short description
        while offset < data.count {
            if data[offset] == 0x00 {
                offset += encoding.terminatorSize
                break
            }
            offset += 1
        }
        
        guard offset < data.count else { return nil }
        return decodeString(data: Data(data[offset...]), encoding: encoding)
    }
    
    private static func parsePictureFrame(data: Data, version: UInt8, tag: inout ID3Tag) {
        guard data.count > 4 else { return }
        
        let encoding = ID3TextEncoding(rawValue: data[0]) ?? .iso88591
        var offset = 1
        
        if version == 2 {
            // ID3v2.2: 3-character image format
            guard offset + 3 <= data.count else { return }
            let imageFormat = String(data: data[offset..<(offset + 3)], encoding: .ascii) ?? "JPG"
            offset += 3
            tag.albumArtMimeType = imageFormat == "PNG" ? "image/png" : "image/jpeg"
        } else {
            // ID3v2.3/v2.4: null-terminated MIME type
            var mimeEnd = offset
            while mimeEnd < data.count && data[mimeEnd] != 0x00 {
                mimeEnd += 1
            }
            tag.albumArtMimeType = String(data: data[offset..<mimeEnd], encoding: .ascii)
            offset = mimeEnd + 1
        }
        
        guard offset < data.count else { return }
        
        // Picture type byte
        _ = data[offset]
        offset += 1
        
        // Skip description (null-terminated)
        while offset < data.count {
            if data[offset] == 0x00 {
                offset += encoding.terminatorSize
                break
            }
            offset += 1
        }
        
        guard offset < data.count else { return }
        tag.albumArtData = Data(data[offset...])
    }
    
    // MARK: - Writing
    
    static func write(tag: ID3Tag, to url: URL) throws {
        var data = try Data(contentsOf: url)
        
        // Remove existing ID3v2 tag
        let existingSize = getExistingID3v2Size(data: data)
        if existingSize > 0 {
            data.removeSubrange(0..<existingSize)
        }
        
        // Remove existing ID3v1 tag
        if data.count > 128 {
            let v1Start = data.count - 128
            if String(data: data[v1Start..<(v1Start + 3)], encoding: .ascii) == "TAG" {
                data.removeSubrange(v1Start..<data.count)
            }
        }
        
        // Build new ID3v2.3 tag
        let tagData = buildID3v2Tag(tag: tag)
        
        // Prepend tag to file
        var finalData = Data()
        finalData.append(tagData)
        finalData.append(data)
        
        try finalData.write(to: url)
    }
    
    static func buildID3v2Tag(tag: ID3Tag) -> Data {
        var frames = Data()
        
        // Write text frames
        appendTextFrame(to: &frames, id: .title, value: tag.title)
        appendTextFrame(to: &frames, id: .artist, value: tag.artist)
        appendTextFrame(to: &frames, id: .album, value: tag.album)
        appendTextFrame(to: &frames, id: .year, value: tag.year)
        appendTextFrame(to: &frames, id: .trackNumber, value: tag.trackNumber)
        appendTextFrame(to: &frames, id: .discNumber, value: tag.discNumber)
        appendTextFrame(to: &frames, id: .composer, value: tag.composer)
        appendTextFrame(to: &frames, id: .albumArtist, value: tag.albumArtist)
        appendTextFrame(to: &frames, id: .bpm, value: tag.bpm)
        appendTextFrame(to: &frames, id: .encoder, value: tag.encoder)
        appendTextFrame(to: &frames, id: .copyright, value: tag.copyright)
        appendTextFrame(to: &frames, id: .publisher, value: tag.publisher)
        appendTextFrame(to: &frames, id: .originalArtist, value: tag.originalArtist)
        appendTextFrame(to: &frames, id: .isrc, value: tag.isrc)
        
        // Write genre with ID3v1 numeric reference if possible
        if let genre = tag.genre, !genre.isEmpty {
            let genreString: String
            if let index = ID3GenreList.genres.firstIndex(of: genre) {
                genreString = "(\(index))\(genre)"
            } else {
                genreString = genre
            }
            appendTextFrame(to: &frames, id: .genre, value: genreString)
        }
        
        // Write comment
        if let comment = tag.comment, !comment.isEmpty {
            appendCommentFrame(to: &frames, id: .comment, value: comment)
        }
        
        // Write lyrics
        if let lyrics = tag.lyrics, !lyrics.isEmpty {
            appendCommentFrame(to: &frames, id: .lyrics, value: lyrics)
        }
        
        // Write album art
        if let artData = tag.albumArtData, !artData.isEmpty {
            appendPictureFrame(to: &frames, imageData: artData,
                             mimeType: tag.albumArtMimeType ?? "image/jpeg")
        }
        
        // Add padding (2048 bytes for future edits)
        let paddingSize = 2048
        
        // Build header
        var header = Data()
        header.append(contentsOf: [0x49, 0x44, 0x33]) // "ID3"
        header.append(contentsOf: [0x03, 0x00])        // Version 2.3.0
        header.append(0x00)                              // No flags
        
        let totalSize = frames.count + paddingSize
        header.append(contentsOf: intToSyncsafe(totalSize))
        
        var result = Data()
        result.append(header)
        result.append(frames)
        result.append(Data(count: paddingSize))
        
        return result
    }
    
    // MARK: - Frame Writing Helpers
    
    private static func appendTextFrame(to data: inout Data, id: ID3FrameID, value: String?) {
        guard let value = value, !value.isEmpty else { return }
        
        var frameContent = Data()
        frameContent.append(0x03) // UTF-8 encoding
        frameContent.append(contentsOf: value.utf8)
        
        appendFrameHeader(to: &data, id: id, size: frameContent.count)
        data.append(frameContent)
    }
    
    private static func appendCommentFrame(to data: inout Data, id: ID3FrameID, value: String) {
        var frameContent = Data()
        frameContent.append(0x03)                              // UTF-8 encoding
        frameContent.append(contentsOf: "eng".utf8)            // Language
        frameContent.append(0x00)                              // Empty description
        frameContent.append(contentsOf: value.utf8)
        
        appendFrameHeader(to: &data, id: id, size: frameContent.count)
        data.append(frameContent)
    }
    
    private static func appendPictureFrame(to data: inout Data, imageData: Data, mimeType: String) {
        var frameContent = Data()
        frameContent.append(0x00)                              // ISO-8859-1 encoding
        frameContent.append(contentsOf: mimeType.utf8)         // MIME type
        frameContent.append(0x00)                              // Null terminator
        frameContent.append(ID3PictureType.frontCover.rawValue) // Front cover
        frameContent.append(0x00)                              // Empty description
        frameContent.append(imageData)
        
        appendFrameHeader(to: &data, id: .attachedPicture, size: frameContent.count)
        data.append(frameContent)
    }
    
    private static func appendFrameHeader(to data: inout Data, id: ID3FrameID, size: Int) {
        data.append(contentsOf: id.rawValue.utf8) // 4-byte frame ID
        
        // Size as big-endian 32-bit integer (ID3v2.3 uses regular integers, not syncsafe)
        data.append(UInt8((size >> 24) & 0xFF))
        data.append(UInt8((size >> 16) & 0xFF))
        data.append(UInt8((size >> 8) & 0xFF))
        data.append(UInt8(size & 0xFF))
        
        data.append(contentsOf: [0x00, 0x00]) // No flags
    }
    
    // MARK: - Utility Functions
    
    private static func getExistingID3v2Size(data: Data) -> Int {
        guard data.count > 10,
              data[0] == 0x49, data[1] == 0x44, data[2] == 0x33 else { return 0 }
        return syncsafeToInt(data[6], data[7], data[8], data[9]) + 10
    }
    
    static func syncsafeToInt(_ b0: UInt8, _ b1: UInt8, _ b2: UInt8, _ b3: UInt8) -> Int {
        return Int(b0 & 0x7F) << 21 | Int(b1 & 0x7F) << 14 |
               Int(b2 & 0x7F) << 7 | Int(b3 & 0x7F)
    }
    
    static func intToSyncsafe(_ value: Int) -> [UInt8] {
        return [
            UInt8((value >> 21) & 0x7F),
            UInt8((value >> 14) & 0x7F),
            UInt8((value >> 7) & 0x7F),
            UInt8(value & 0x7F)
        ]
    }
    
    private static func readFixedString(_ data: Data, offset: Int, length: Int) -> String? {
        guard offset + length <= data.count else { return nil }
        let slice = data[offset..<(offset + length)]
        
        // Try UTF-8 first, then Latin1
        var str = String(data: slice, encoding: .utf8) ?? String(data: slice, encoding: .isoLatin1)
        
        // Trim null characters and whitespace
        str = str?.trimmingCharacters(in: .init(charactersIn: "\0").union(.whitespaces))
        
        return str?.isEmpty == true ? nil : str
    }
    
    private static func decodeString(data: Data, encoding: ID3TextEncoding) -> String? {
        var cleanData = data
        
        // Remove trailing null terminators
        while !cleanData.isEmpty && cleanData.last == 0x00 {
            cleanData.removeLast()
        }
        
        guard !cleanData.isEmpty else { return nil }
        
        let str = String(data: cleanData, encoding: encoding.encoding)
        return str?.trimmingCharacters(in: .init(charactersIn: "\0").union(.whitespaces))
    }
    
    private static func parseGenreString(_ value: String) -> String? {
        guard !value.isEmpty else { return nil }
        
        // Handle "(XX)Genre Name" format
        if value.hasPrefix("(") {
            if let closingParen = value.firstIndex(of: ")") {
                let numberStr = value[value.index(after: value.startIndex)..<closingParen]
                let afterParen = String(value[value.index(after: closingParen)...])
                
                if !afterParen.isEmpty {
                    return afterParen
                }
                
                if let number = Int(numberStr), number < ID3GenreList.genres.count {
                    return ID3GenreList.genres[number]
                }
            }
        }
        
        // Handle plain number
        if let number = Int(value), number < ID3GenreList.genres.count {
            return ID3GenreList.genres[number]
        }
        
        return value
    }
}
