import Cocoa

import Cocoa

class ScreenPainter {
    
    static let shared = ScreenPainter() // Singleton instance
    private var overlayWindow: OverlayWindow?
    
    private init() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        if !accessEnabled {
            print("Accessibility access is not enabled. Please enable it in System Preferences.")
        }
    }
    
    func addOverlay(x: Double, y: Double, height: Double, width: Double, number: Int, caption: String) {
        let windowRect = NSRect(x: x, y: y, width: width, height: height)
        self.overlayWindow = OverlayWindow(contentRect: windowRect, styleMask: .borderless, backing: .buffered, defer: false)
        self.overlayWindow?.orderFrontRegardless()
        
//        DispatchQueue.main.async {
//            if let existingWindow = self.overlayWindow {
//                existingWindow.setContentSize(NSSize(width: width, height: height))
//                existingWindow.setFrameOrigin(NSPoint(x: x, y: y))
//                // Update content or caption if needed
//            } else {
//                let windowRect = NSRect(x: x, y: y, width: width, height: height)
//                self.overlayWindow = OverlayWindow(contentRect: windowRect, styleMask: .borderless, backing: .buffered, defer: false)
//                self.overlayWindow?.orderFrontRegardless()
//                self.overlayWindow?.close()
//            }
//        }
    }
    
    func clearHighlights() {
        self.overlayWindow?.orderOut(nil)
        // self.overlayWindow = nil // Release the window to avoid memory leaks
//        DispatchQueue.main.async { // Ensure UI updates are on the main thread
//            
//        }
    }
}

class OverlayWindow: NSWindow {
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: .borderless, backing: backingStoreType, defer: flag)
        self.backgroundColor = NSColor.yellow.withAlphaComponent(0.3)
        self.isOpaque = false
        self.level = .floating // You might want to use .popUpMenu or .statusBar for overlays
        self.ignoresMouseEvents = true
    }
}


class HighlightView: NSView {
    var caption: String
    var highlightColor: NSColor

    init(frame frameRect: NSRect, caption: String, highlightColor: NSColor = NSColor.yellow.withAlphaComponent(0.3)) {
        self.caption = caption
        self.highlightColor = highlightColor
        super.init(frame: frameRect)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Draw highlight
        highlightColor.set()
        let path = NSBezierPath(rect: bounds)
        path.fill()

        // Draw caption
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: NSColor.black,
            .paragraphStyle: paragraphStyle
        ]

        let textHeight = caption.size(withAttributes: attributes).height
        let textRect = NSRect(x: 0, y: -textHeight - 5, width: bounds.width, height: textHeight)
        caption.draw(in: textRect, withAttributes: attributes)
    }
}

//
//class DrawingView: NSView {
//    var circleText: String = "1"
//    var captionText: String = "Component"
//
//    override func draw(_ dirtyRect: NSRect) {
//        super.draw(dirtyRect)
//
//        // Draw a circle
////        let path = NSBezierPath(ovalIn: NSRect(x: 10, y: bounds.height - 70, width: 60, height: 60))
////        NSColor.systemRed.setFill()
////        path.fill()
//
//        // Draw a number inside the circle
////        let attributes: [NSAttributedString.Key: Any] = [
////            .font: NSFont.systemFont(ofSize: 24),
////            .foregroundColor: NSColor.white
////        ]
////        let string = NSAttributedString(string: circleText, attributes: attributes)
////        let stringSize = string.size()
////        let stringRect = NSRect(x: 40 - stringSize.width / 2, y: -40 - stringSize.height / 2 + CGFloat(bounds.height), width: stringSize.width, height: stringSize.height)
////        string.draw(in: stringRect)
//        
//        
//        let rectHeight: CGFloat = 50
////        let rectY = 0
//        let rectangle = NSRect(x: 0, y: 0, width: bounds.width, height: rectHeight)
//        NSColor.white.withAlphaComponent(0.9).setFill()
//        __NSRectFillUsingOperation(rectangle, .sourceOver)
//        
//        let captionAttributes: [NSAttributedString.Key: Any] = [
//            .font: NSFont(name: "San Francisco", size: 18) ?? NSFont.systemFont(ofSize: 18),
//            .foregroundColor: NSColor.black
//        ]
//        let captionString = NSAttributedString(string: captionText, attributes: captionAttributes)
//        captionString.draw(at: CGPoint(x: 10, y: rectHeight - 20 - stringSize.height / 2))
//    
//    }
//}
