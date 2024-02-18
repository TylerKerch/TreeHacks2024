import Cocoa
import ImageIO

extension NSImageView {
    func loadGif(url: URL) {
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return
        }

        let count = CGImageSourceGetCount(imageSource)
        var images = [CGImage]()
        var delays = [Int]()

        for i in 0..<count {
            if let image = CGImageSourceCreateImageAtIndex(imageSource, i, nil) {
                images.append(image)
            }

            let delaySeconds = gifDelayForImageAtIndex(index: Int(i), source: imageSource)
            delays.append(Int(delaySeconds * 1000.0)) // Convert to ms
        }

        animate(images: images, delays: delays)
    }

    private func gifDelayForImageAtIndex(index: Int, source: CGImageSource) -> Double {
        var delay = 0.1

        let cfProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil)
        let gifProperties: CFDictionary = unsafeBitCast(CFDictionaryGetValue(cfProperties, Unmanaged.passUnretained(kCGImagePropertyGIFDictionary).toOpaque()), to: CFDictionary.self)

        var delayObject: AnyObject = unsafeBitCast(CFDictionaryGetValue(gifProperties, Unmanaged.passUnretained(kCGImagePropertyGIFUnclampedDelayTime).toOpaque()), to: AnyObject.self)
        if delayObject.doubleValue == 0 {
            delayObject = unsafeBitCast(CFDictionaryGetValue(gifProperties, Unmanaged.passUnretained(kCGImagePropertyGIFDelayTime).toOpaque()), to: AnyObject.self)
        }

        delay = delayObject as? Double ?? 0

        if delay < 0.1 {
            delay = 0.1 // Make sure they're not too fast
        }

        return delay
    }

    private func animate(images: [CGImage], delays: [Int]) {
        var frame: Int = 0
        var time: Int = 0

        Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
            time += 10
            if time >= delays[frame] {
                time = 0
                frame += 1
                if frame >= images.count {
                    frame = 0
                }

                self.image = NSImage(cgImage: images[frame], size: NSSize(width: images[frame].width, height: images[frame].height))
            }
        }
    }
}
