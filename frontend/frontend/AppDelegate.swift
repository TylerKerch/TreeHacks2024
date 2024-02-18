import Cocoa
import HotKey

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var menuBarController: MenuBarController!
    var voiceRecorder: VoiceRecorder!
    var screenReader: ScreenReader!
    var screenPainter: ScreenPainter!
    var textSpeaker: TextSpeaker!
    
    var hotKeyScreenReader: HotKey?
    var hotKeyVoiceRecorder: HotKey?
    var hotKeyTextReader: HotKey?
    
    var gifWindowController: GifWindowController?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Initialize the menu bar controller when the app finishes launching
        menuBarController = MenuBarController()
        voiceRecorder = VoiceRecorder()
        screenReader = ScreenReader()
        screenPainter = ScreenPainter()
        textSpeaker = TextSpeaker()
        
        var socket = ClientSocket(painter: screenPainter, speaker: textSpeaker)
        
        if let mainWindow = NSApplication.shared.windows.first {
            mainWindow.close()
        }
        
        hotKeyVoiceRecorder = HotKey(key: .grave, modifiers: [])
        hotKeyVoiceRecorder?.keyDownHandler = {
            self.voiceRecorder.startRecording()
            
            if self.gifWindowController == nil {
                self.gifWindowController = GifWindowController()
            }
            self.gifWindowController?.showWindow(nil)
        }
        
        hotKeyVoiceRecorder?.keyUpHandler = {
            let query = self.voiceRecorder.stopRecording()
            let image = self.screenReader.readScreenContents()
            socket.sendUIBoxesRequest(imageBase64: image, query: query)
            
            self.gifWindowController?.close()
            self.gifWindowController = nil
        }
        
        preloadGif()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
