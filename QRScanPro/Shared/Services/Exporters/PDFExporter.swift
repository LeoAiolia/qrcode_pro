import CoreGraphics
import Foundation

enum PDFExporter {
    static func data(from cgImage: CGImage) -> Data? {
        let mutData = NSMutableData()
        guard let consumer = CGDataConsumer(data: mutData as CFMutableData) else {
            return nil
        }
        var mediaBox = CGRect(x: 0, y: 0, width: CGFloat(cgImage.width), height: CGFloat(cgImage.height))
        guard let ctx = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            return nil
        }
        ctx.beginPDFPage(nil)
        ctx.draw(cgImage, in: mediaBox)
        ctx.endPDFPage()
        ctx.closePDF()
        return mutData as Data
    }
}
