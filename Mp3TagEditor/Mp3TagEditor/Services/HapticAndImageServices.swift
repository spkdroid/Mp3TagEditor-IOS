import UIKit
import SwiftUI

// MARK: - Haptic Manager
final class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard UserDefaults.standard.bool(forKey: "hapticFeedbackEnabled") != false else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard UserDefaults.standard.bool(forKey: "hapticFeedbackEnabled") != false else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    func selection() {
        guard UserDefaults.standard.bool(forKey: "hapticFeedbackEnabled") != false else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - Image Processing Service
struct ImageService {
    
    /// Compress image data to a target size
    static func compress(imageData: Data, maxSizeKB: Int = 500) -> Data? {
        guard let image = UIImage(data: imageData) else { return nil }
        return compress(image: image, maxSizeKB: maxSizeKB)
    }
    
    static func compress(image: UIImage, maxSizeKB: Int = 500) -> Data? {
        let maxBytes = maxSizeKB * 1024
        var compression: CGFloat = 1.0
        var data = image.jpegData(compressionQuality: compression)
        
        while let currentData = data, currentData.count > maxBytes, compression > 0.1 {
            compression -= 0.1
            data = image.jpegData(compressionQuality: compression)
        }
        
        return data
    }
    
    /// Resize image to fit within a max dimension
    static func resize(image: UIImage, maxDimension: CGFloat = 600) -> UIImage {
        let size = image.size
        let maxSide = max(size.width, size.height)
        
        guard maxSide > maxDimension else { return image }
        
        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    /// Create a square thumbnail
    static func squareThumbnail(from image: UIImage, size: CGFloat = 300) -> UIImage {
        let side = min(image.size.width, image.size.height)
        let origin = CGPoint(
            x: (image.size.width - side) / 2,
            y: (image.size.height - side) / 2
        )
        let cropRect = CGRect(origin: origin, size: CGSize(width: side, height: side))
        
        guard let cgImage = image.cgImage?.cropping(to: cropRect) else { return image }
        let cropped = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
        
        return resize(image: cropped, maxDimension: size)
    }
    
    /// Detect MIME type from image data
    static func mimeType(for data: Data) -> String {
        guard data.count >= 4 else { return "image/jpeg" }
        
        let bytes = [UInt8](data.prefix(4))
        
        if bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47 {
            return "image/png"
        }
        if bytes[0] == 0xFF && bytes[1] == 0xD8 {
            return "image/jpeg"
        }
        if bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46 {
            return "image/gif"
        }
        if bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 {
            return "image/webp"
        }
        
        return "image/jpeg"
    }
}
