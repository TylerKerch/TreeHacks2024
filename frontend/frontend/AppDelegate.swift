import Cocoa
import HotKey

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var menuBarController: MenuBarController!
    var voiceRecorder: VoiceRecorder!
    var screenReader: ScreenReader!
    var screenPainter: ScreenPainter!
    var textReader: TextSpeaker!
    
    var hotKeyScreenReader: HotKey?
    var hotKeyVoiceRecorder: HotKey?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Initialize the menu bar controller when the app finishes launching
        menuBarController = MenuBarController()
        voiceRecorder = VoiceRecorder()
        screenReader = ScreenReader()
        screenPainter = ScreenPainter()
        textReader = TextSpeaker()
        
        var socket = ClientSocket(painter: <#T##ScreenPainter#>)
        
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
            let query = self.voiceRecorder.stopRecording()
            let image = self.screenReader.readScreenContents()
            socket.sendUIBoxesRequest(imageBase64: image, query: query)
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
