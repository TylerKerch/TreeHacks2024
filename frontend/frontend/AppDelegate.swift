import Cocoa
import HotKey

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var menuBarController: MenuBarController!
    var voiceRecorder: VoiceRecorder!
    var screenPainter: ScreenPainter!
    var textReader: TextReader!
    
    var hotKeyScreenReader: HotKey?
    var hotKeyVoiceRecorder: HotKey?
    var hotKeyTextReader: HotKey?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Initialize the menu bar controller when the app finishes launching
        menuBarController = MenuBarController()
        voiceRecorder = VoiceRecorder()
        screenPainter = ScreenPainter()
        textReader = TextReader()
        
        if let mainWindow = NSApplication.shared.windows.first {
            mainWindow.close()
        }
        
        hotKeyScreenReader = HotKey(key: .k, modifiers: [.command, .shift])
        hotKeyScreenReader?.keyDownHandler = {
            self.screenPainter.addOverlay(x: 50, y: 50, height: 200, width: 200, text: "1")
            self.screenPainter.addOverlay(x: 450, y: 450, height: 200, width: 200, text: "2")
            self.screenPainter.addOverlay(x: 850, y: 850, height: 200, width: 200, text: "3")
        }
        
        hotKeyVoiceRecorder = HotKey(key: .grave, modifiers: [])
        hotKeyVoiceRecorder?.keyDownHandler = {
            self.voiceRecorder.startRecording()
        }
        hotKeyVoiceRecorder?.keyUpHandler = {
            self.voiceRecorder.stopRecording()
            // Fill in API logic to fetch string
            self.textReader.readText(s: "I CAN HELP YOU WITH THAT OLD MAN")
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
