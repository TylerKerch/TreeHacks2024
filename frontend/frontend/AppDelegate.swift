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
    
    var socket: ClientSocket!
    var gifWindowController: GifWindowController?
    var readScreenContentsTimer: Timer?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Initialize the menu bar controller when the app finishes launching
        menuBarController = MenuBarController()
        voiceRecorder = VoiceRecorder()
        screenReader = ScreenReader()
        screenPainter = ScreenPainter()
        textSpeaker = TextSpeaker()
        
        socket = ClientSocket(painter: screenPainter, speaker: textSpeaker)
        
        if let mainWindow = NSApplication.shared.windows.first {
            mainWindow.close()
        }
        
        // UNCOMMENT WHEN WE START CONNECTING W LOCALHOST
//        scheduleScreenshotTimer()
        
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
            self.socket.sendQueryRequest(query: query)
            
            self.gifWindowController?.close()
            self.gifWindowController = nil
        }
        
        preloadGif()
    }
    
    func scheduleScreenshotTimer() {
        readScreenContentsTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            let image = self?.screenReader.readScreenContents()
            guard let unwrappedImage = image else {
                print("Could not unwrap image")
                return
            }
            self?.socket.sendScreenshotRequest(image: unwrappedImage)
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
