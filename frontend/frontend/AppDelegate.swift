import Cocoa
import HotKey

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var menuBarController: MenuBarController!
    var voiceRecorder: VoiceRecorder!
    var screenPainter: ScreenPainter!
    var hotKey: HotKey?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Initialize the menu bar controller when the app finishes launching
        menuBarController = MenuBarController()
        voiceRecorder = VoiceRecorder()
        screenPainter = ScreenPainter()
        
        if let mainWindow = NSApplication.shared.windows.first {
            mainWindow.close()
        }
        
        hotKey = HotKey(key: .k, modifiers: [.command, .shift])
        hotKey?.keyDownHandler = {
            self.screenPainter.addOverlay(x: 50, y: 50, height: 200, width: 200, text: "1")
            self.screenPainter.addOverlay(x: 450, y: 450, height: 200, width: 200, text: "2")
            self.screenPainter.addOverlay(x: 850, y: 850, height: 200, width: 200, text: "3")
        }
        
//        hotKey = HotKey(key: .j, modifiers: [.command, .shift])
//        hotKey?.keyDownHandler = {
//            self.screenPainter.clearHighlights()
//        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
