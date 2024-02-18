import Cocoa

class ScreenReader {
    func readScreenContents() -> String {
        
        let screenRect = NSScreen.main?.frame ?? CGRect.zero
        guard let image = CGWindowListCreateImage(screenRect, .optionOnScreenOnly, kCGNullWindowID, [.bestResolution, .boundsIgnoreFraming]) else { return "" }
        
        // Convert CGImage to Data
        let bitmapRep = NSBitmapImageRep(cgImage: image)
        guard let imageData = bitmapRep.representation(using: .png, properties: [:]) else { return "" }
        
        return imageData.base64EncodedString()

    }
}
