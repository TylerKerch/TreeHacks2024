import AppKit

class GifWindowController: NSWindowController {
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 200),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        self.init(window: window)
        configureWindowProperties()
        positionWindowAtScreenBottom()
    }
    
    private func configureWindowProperties() {
        // Create and configure the visual effect view
        let visualEffectView = NSVisualEffectView()
        visualEffectView.state = .active
        visualEffectView.wantsLayer = true
        visualEffectView.layer?.backgroundColor = NSColor.lightGray.withAlphaComponent(0.3).cgColor // Set translucent gray background
        visualEffectView.layer?.cornerRadius = 40
        visualEffectView.layer?.masksToBounds = true

        // Set the visual effect view as the window's content view
        window?.contentView = visualEffectView
        window?.backgroundColor = .clear
        window?.level = .floating
        window?.isOpaque = false
        window?.ignoresMouseEvents = true

        // Ensure GifViewController's view is added to visualEffectView
        let gifViewController = GifViewController()
        visualEffectView.addSubview(gifViewController.view)
        gifViewController.view.frame = visualEffectView.bounds // Adjust as necessary
        gifViewController.view.autoresizingMask = [.width, .height] // Adjust for proper resizing
    }
    
    private func positionWindowAtScreenBottom() {
        if let screen = NSScreen.main {
            let screenWidth = screen.frame.width
            print(screen.frame.height, screen.frame.width)
            let windowHeight = window?.frame.height ?? 0
            let windowX = (screenWidth - (window?.frame.width ?? 0)) / 2
            let windowY = windowHeight * 0.15

            window?.setFrameOrigin(NSPoint(x: windowX, y: windowY))
        }
    }
}

// Global or shared instance to hold the preloaded GIF
var preloadedGifImage: NSImage?

// Function to preload the GIF into memory
func preloadGif() {
    if let gifUrl = Bundle.main.url(forResource: "AudioInput", withExtension: "gif"),
       let image = NSImage(contentsOf: gifUrl) {
        preloadedGifImage = image
    }
}

class GifViewController: NSViewController {
    override func loadView() {
        let imageView = NSImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        self.view = imageView

        // Use the preloaded GIF image if available
        if let preloadedImage = preloadedGifImage {
            imageView.image = preloadedImage
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.widthAnchor.constraint(equalToConstant: 200).isActive = true
        view.heightAnchor.constraint(equalToConstant: 200).isActive = true
    }
}
