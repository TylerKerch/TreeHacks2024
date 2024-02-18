import Cocoa

class ScreenPainter {
    
    var highlightWindows: [OverlayWindow] = []
    
    init() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        if !accessEnabled {
            print("Accessibility access is not enabled. Please enable it in System Preferences.")
        }
    }
    
    func addOverlay(x: Int, y: Int, height: Int, width: Int, text: String) {
//        let screenRect = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let windowRect = NSRect(x: x, y: y, width: width, height: height)
        
        // Initialize the overlay window and the drawing view
        let overlayWindow = OverlayWindow(contentRect: windowRect, styleMask: .borderless, backing: .buffered, defer: false)
        let drawingView = DrawingView(frame: windowRect)
        
        // Set the custom view as the window's content view
        overlayWindow.contentView = drawingView
        drawingView.customText = text
        
        // Make the overlay window visible
        overlayWindow.orderFront(nil)
        highlightWindows.append(overlayWindow)
    }
    
    @objc func clearHighlights() {
        for window in highlightWindows {
            window.close()
        }
        highlightWindows.removeAll()
    }
}

class OverlayWindow: NSWindow {
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: .borderless, backing: backingStoreType, defer: flag)
        self.backgroundColor = NSColor.yellow.withAlphaComponent(0.3)
        self.isOpaque = false
        self.level = .mainMenu
        self.ignoresMouseEvents = true
    }
}

class DrawingView: NSView {
    var customText: String = "1"

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Draw a circle
        let path = NSBezierPath(ovalIn: NSRect(x: 10, y: 10, width: 60, height: 60))
        NSColor.systemRed.setFill()
        path.fill()

        // Draw a number inside the circle
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 24),
            .foregroundColor: NSColor.white
        ]
        let string = NSAttributedString(string: customText, attributes: attributes)
        let stringSize = string.size()
        let stringRect = NSRect(x: 40 - stringSize.width / 2, y: 40 - stringSize.height / 2, width: stringSize.width, height: stringSize.height)
        string.draw(in: stringRect)
    }
}
