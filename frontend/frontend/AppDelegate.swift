import Cocoa
import HotKey

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var menuBarController: MenuBarController!
    var voiceRecorder: VoiceRecorder!
    var textReader: TextReader!
    
    var hotKeyScreenReader: HotKey?
    var hotKeyVoiceRecorder: HotKey?
    var hotKeyTextReader: HotKey?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Initialize the menu bar controller when the app finishes launching
        menuBarController = MenuBarController()
        voiceRecorder = VoiceRecorder()
        textReader = TextReader()
        
        if let mainWindow = NSApplication.shared.windows.first {
            mainWindow.close()
        }
        
        hotKeyScreenReader = HotKey(key: .k, modifiers: [.command, .shift])
        hotKeyScreenReader?.keyDownHandler = {
            ScreenReader.readScreenContents()
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
