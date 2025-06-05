import SwiftUI

struct DeviceMockupView: View {
    let image: NSImage?
    let deviceType: ContentView.DeviceType
    let backgroundColor: Color
    let textOverlay: String

    var body: some View {
        ZStack {
            backgroundColor // Apply the selected background color first

            VStack {
                if let nsImage = image {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: deviceCornerRadius))
                        .frame(width: deviceFrame.width, height: deviceFrame.height)
                        .overlay(
                            RoundedRectangle(cornerRadius: deviceCornerRadius)
                                .stroke(Color.black.opacity(0.7), lineWidth: deviceBorderWidth)
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                        .overlay(
                            Text(textOverlay)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.5))
                                .cornerRadius(5)
                                .padding(10), // Padding from the edges of the image
                            alignment: .bottom // Position at the bottom, can be changed
                        )
                } else {
                    Text("Import an image to see the preview")
                        .foregroundColor(.secondary)
                }
            }
        }
        .edgesIgnoringSafeArea(.all) // Allow background to fill the entire ZStack area
    }

    private var deviceFrame: (width: CGFloat, height: CGFloat) {
        switch deviceType {
        case .iPhone:
            return (200, 400) // Example dimensions, adjust as needed
        case .iPad:
            return (300, 400) // Example dimensions
        case .mac:
            return (450, 280) // Example dimensions
        }
    }

    private var deviceCornerRadius: CGFloat {
        switch deviceType {
        case .iPhone:
            return 25
        case .iPad:
            return 20
        case .mac:
            return 10
        }
    }

    private var deviceBorderWidth: CGFloat {
        switch deviceType {
        case .iPhone, .iPad:
            return 8
        case .mac:
            return 15 // Thicker border for Mac to simulate a display bezel
        }
    }
}

struct DeviceMockupView_Previews: PreviewProvider {
    static var previews: some View {
        // Example with a placeholder image for previewing
        let placeholderImage = NSImage(systemSymbolName: "photo", accessibilityDescription: nil)
        
        Group {
            DeviceMockupView(image: placeholderImage, deviceType: .iPhone, backgroundColor: .blue, textOverlay: "iPhone Preview Text")
                .previewLayout(.sizeThatFits)
                .frame(width: 300, height: 500)
            
            DeviceMockupView(image: placeholderImage, deviceType: .iPad, backgroundColor: .green, textOverlay: "iPad Preview Text")
                .previewLayout(.sizeThatFits)
                .frame(width: 400, height: 500)

            DeviceMockupView(image: placeholderImage, deviceType: .mac, backgroundColor: .purple, textOverlay: "Mac Preview Text")
                .previewLayout(.sizeThatFits)
                .frame(width: 550, height: 380)
        }
    }
}
