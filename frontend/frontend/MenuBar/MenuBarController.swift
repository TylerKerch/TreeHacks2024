import Cocoa

class MenuBarController {
    private var statusItem: NSStatusItem
    
    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "textformat.abc", accessibilityDescription: "Screen Reader")
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Read Screen", action: #selector(readScreen), keyEquivalent: "r"))
        menu.addItem(NSMenuItem(title: "Move Cursor", action: #selector(moveCursor), keyEquivalent: "m"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    
    @objc private func readScreen() {
        ScreenReader.readScreenContents()
    }
    
    @objc private func moveCursor() {
        CursorController.moveCursorToCenter()
    }
}
