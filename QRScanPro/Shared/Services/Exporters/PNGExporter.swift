import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum PNGExporter {
    static func data(from cgImage: CGImage) -> Data? {
        let mutData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            mutData as CFMutableData,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            return nil
        }
        CGImageDestinationAddImage(destination, cgImage, nil)
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }
        return mutData as Data
    }
}
