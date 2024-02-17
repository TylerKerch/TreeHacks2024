import Cocoa

class CursorController {
    static func moveCursorToCenter() {
        if let screen = NSScreen.main {
            let center = CGPoint(x: screen.frame.midX, y: screen.frame.midY)
            CGWarpMouseCursorPosition(center)
        }
    }
}
