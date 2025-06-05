import SwiftUI

extension View {
    func renderAsImage(size: NSSize) -> NSImage? {
        let hostingView = NSHostingView(rootView: self.frame(width: size.width, height: size.height))
        hostingView.frame = CGRect(origin: .zero, size: size)

        guard let bitmapRep = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
            return nil
        }
        
        hostingView.cacheDisplay(in: hostingView.bounds, to: bitmapRep)
        
        let image = NSImage(size: bitmapRep.size)
        image.addRepresentation(bitmapRep)
        
        return image
    }
}
