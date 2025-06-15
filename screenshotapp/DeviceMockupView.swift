import SwiftUI

struct DeviceMockupView: View {
    let userScreenshot: NSImage?
    let deviceFrameImage: NSImage
    let screenAreaPixels: CGRect
    let screenCornerRadius: CGFloat

    var body: some View {
        // The base is the device frame image itself.
        Image(nsImage: deviceFrameImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .overlay(
                // Inside the overlay, we place the user's screenshot.
                // We use a GeometryReader to get the size of the rendered frame image,
                // so we can scale and position the screenshot accurately.
                GeometryReader { geometry in
                    if let screenshot = userScreenshot {
                        Image(nsImage: screenshot)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            // Calculate the frame for the screenshot based on the geometry
                            // of the rendered device frame and the screenAreaPixels rect.
                            .frame(width: geometry.size.width * (screenAreaPixels.width / deviceFrameImage.size.width),
                                   height: geometry.size.height * (screenAreaPixels.height / deviceFrameImage.size.height))
                            .clipShape(RoundedRectangle(cornerRadius: screenCornerRadius))
                            // Position the screenshot in the correct place.
                            .position(x: geometry.size.width * (screenAreaPixels.midX / deviceFrameImage.size.width),
                                      y: geometry.size.height * (screenAreaPixels.midY / deviceFrameImage.size.height))
                    } else {
                        // Placeholder view if no screenshot is available
                        RoundedRectangle(cornerRadius: screenCornerRadius)
                            .fill(Color.black)
                            .frame(width: geometry.size.width * (screenAreaPixels.width / deviceFrameImage.size.width),
                                   height: geometry.size.height * (screenAreaPixels.height / deviceFrameImage.size.height))
                            .position(x: geometry.size.width * (screenAreaPixels.midX / deviceFrameImage.size.width),
                                      y: geometry.size.height * (screenAreaPixels.midY / deviceFrameImage.size.height))
                    }
                }
            )
    }
}

struct DeviceMockupView_Previews: PreviewProvider {
    static var previews: some View {
        // Ensure you have an image named "iPhone_15_Pro_Frame" in your assets for this preview to work.
        let frameImage = NSImage(named: "iPhone_15_Pro_Frame")
        let placeholderScreenshot = NSImage(systemSymbolName: "photo", accessibilityDescription: nil)
        
        Group {
            if let frameImage = frameImage {
                DeviceMockupView(
                    userScreenshot: placeholderScreenshot,
                    deviceFrameImage: frameImage,
                    screenAreaPixels: CGRect(x: 88, y: 86, width: 1118, height: 2426),
                    screenCornerRadius: 54.0
                )
                .previewLayout(.sizeThatFits)
                .frame(width: 300, height: 600)
                .padding()
                .background(Color.gray)
            } else {
                Text("Preview requires 'iPhone_15_Pro_Frame' in Assets.xcassets")
            }
        }
    }
}
