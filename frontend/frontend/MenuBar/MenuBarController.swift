import Cocoa

class MenuBarController {
    private var statusItem: NSStatusItem
    
    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(named: "MenuIcon")
        }
        
        let menu = NSMenu()
        let moveCursorItem = NSMenuItem(title: "Move Cursor", action: #selector(moveCursor), keyEquivalent: "m")
        moveCursorItem.target = self
        menu.addItem(moveCursorItem)
        
        let readScreenItem = NSMenuItem(title: "Read Screen", action: #selector(readScreen), keyEquivalent: "k")
        readScreenItem.keyEquivalentModifierMask = [.command, .shift]
        readScreenItem.target = self
        menu.addItem(readScreenItem)
        
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
