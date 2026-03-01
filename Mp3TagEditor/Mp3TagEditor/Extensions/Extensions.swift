import SwiftUI

// MARK: - Color + Hex
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        guard hexSanitized.count == 6,
              let hexNumber = UInt64(hexSanitized, radix: 16) else {
            return nil
        }
        
        let r = Double((hexNumber & 0xFF0000) >> 16) / 255
        let g = Double((hexNumber & 0x00FF00) >> 8) / 255
        let b = Double(hexNumber & 0x0000FF) / 255
        
        self.init(red: r, green: g, blue: b)
    }
    
    func toHex() -> String {
        guard let components = UIColor(self).cgColor.components else { return "#000000" }
        
        let r = Int(max(0, min(1, components[0])) * 255)
        let g = Int(max(0, min(1, components.count > 1 ? components[1] : 0)) * 255)
        let b = Int(max(0, min(1, components.count > 2 ? components[2] : 0)) * 255)
        
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

// MARK: - View Extensions
extension View {
    func hapticOnTap(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded {
                HapticManager.shared.impact(style)
            }
        )
    }
    
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - String Extensions
extension String {
    var isNotEmpty: Bool {
        !isEmpty
    }
    
    func truncated(to maxLength: Int, trailing: String = "...") -> String {
        if count <= maxLength { return self }
        return String(prefix(maxLength)) + trailing
    }
    
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

// MARK: - Data Extensions
extension Data {
    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
    
    var sizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(count), countStyle: .file)
    }
    
    var isJPEG: Bool {
        count >= 2 && self[0] == 0xFF && self[1] == 0xD8
    }
    
    var isPNG: Bool {
        count >= 4 && self[0] == 0x89 && self[1] == 0x50 && self[2] == 0x4E && self[3] == 0x47
    }
}

// MARK: - Date Extensions
extension Date {
    var relativeFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

// MARK: - URL Extensions
extension URL {
    var isMP3: Bool {
        pathExtension.lowercased() == "mp3"
    }
    
    var fileSizeFormatted: String? {
        guard let values = try? resourceValues(forKeys: [.fileSizeKey]),
              let size = values.fileSize else { return nil }
        return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }
}

// MARK: - Array Extensions
extension Array where Element == MP3File {
    var totalSize: Int64 {
        reduce(0) { $0 + $1.fileSize }
    }
    
    var totalSizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
}

// MARK: - Shake Gesture (for undo)
extension UIDevice {
    static let deviceDidShakeNotification = Notification.Name(rawValue: "deviceDidShakeNotification")
}

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: UIDevice.deviceDidShakeNotification, object: nil)
        }
    }
}

// MARK: - Shake View Modifier
struct DeviceShakeViewModifier: ViewModifier {
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.deviceDidShakeNotification)) { _ in
                action()
            }
    }
}

extension View {
    func onShake(perform action: @escaping () -> Void) -> some View {
        self.modifier(DeviceShakeViewModifier(action: action))
    }
}
