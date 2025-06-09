import SwiftUI

struct DeviceMockupView: View {
    let image: NSImage?
    let deviceType: DeviceType
    let backgroundColor: Color
    // Text rendering removed from DeviceMockupView
    // let textOverlay: String
    // let textColor: Color
    // let textAlignment: Alignment
    // let fontName: String
    // let fontSize: CGFloat

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
                        // Device specific details overlay (e.g., notch, buttons, camera)
                        .overlay(
                            ZStack {
                                // iPhone specific details
                                if deviceType == .iPhone {
                                    // Dynamic Island / Notch
                                    Capsule()
                                        .fill(Color.black) // Solid black for notch
                                        .frame(width: deviceFrame.width * 0.35, height: deviceFrame.height * 0.035)
                                        .offset(y: (-deviceFrame.height / 2) + (deviceFrame.height * 0.035 / 2) + deviceBorderWidth + 2) // Position at top inside border

                                    // Subtle side button hints (very simplified)
                                    Capsule().fill(Color.black.opacity(0.3)).frame(width: 3, height: 30).offset(x: -deviceFrame.width/2 - 1.5, y: -deviceFrame.height * 0.1)
                                    Capsule().fill(Color.black.opacity(0.3)).frame(width: 3, height: 20).offset(x: -deviceFrame.width/2 - 1.5, y: -deviceFrame.height * 0.1 - 35)
                                    Capsule().fill(Color.black.opacity(0.3)).frame(width: 3, height: 50).offset(x: deviceFrame.width/2 + 1.5, y: -deviceFrame.height * 0.05)
                                }
                                
                                // iPad specific details
                                if deviceType == .iPad {
                                    // Front camera hint
                                    Circle()
                                        .fill(Color.black.opacity(0.4))
                                        .frame(width: 8, height: 8)
                                        .offset(y: (-deviceFrame.height / 2) + deviceBorderWidth + 8)
                                }
                            }
                        )
                        // Text Overlay logic removed
                } else {
                    Text("Import an image to see the preview")
                        .foregroundColor(.secondary)
                }
            }
            // Mac specific stand
            if deviceType == .mac {
                MacStandView(frameWidth: deviceFrame.width)
                    .offset(y: (deviceFrame.height / 2) + 20) // Position below the Mac frame
            }
        }
        .edgesIgnoringSafeArea(.all) // Allow background to fill the entire ZStack area
    }

    private var deviceFrame: (width: CGFloat, height: CGFloat) {
        // Adjusted for slightly more realistic proportions for Phase 1
        switch deviceType {
        case .iPhone:
            return (200, 410) // Slightly taller for iPhone
        case .iPad:
            return (300, 420) // Slightly different aspect for iPad
        case .mac:
            return (450, 280)
        }
    }

    private var deviceCornerRadius: CGFloat {
        switch deviceType {
        case .iPhone:
            return 35 // More pronounced rounding for modern iPhones
        case .iPad:
            return 25 // iPad Pro-like rounding
        case .mac:
            return 10
        }
    }

    private var deviceBorderWidth: CGFloat {
        switch deviceType {
        case .iPhone:
            return 6 // Thinner bezel for modern iPhones
        case .iPad:
            return 8
        case .mac:
            return 15
        }
    }
}

struct DeviceMockupView_Previews: PreviewProvider {
    static var previews: some View {
        let placeholderImage = NSImage(systemSymbolName: "photo", accessibilityDescription: nil)
        
        Group {
            DeviceMockupView(image: placeholderImage, 
                             deviceType: .iPhone, 
                             backgroundColor: .blue 
                             // textOverlay: "iPhone Preview Text", 
                             // textColor: .white, 
                             // textAlignment: .bottom,
                             // fontName: "System Font",
                             // fontSize: 18
                             )
                .previewLayout(.sizeThatFits)
                .frame(width: 300, height: 600)
            
            DeviceMockupView(image: placeholderImage, 
                             deviceType: .iPad, 
                             backgroundColor: .green 
                             // textOverlay: "iPad Preview Text", 
                             // textColor: .black, 
                             // textAlignment: .center,
                             // fontName: "Helvetica Neue",
                             // fontSize: 22
                             )
                .previewLayout(.sizeThatFits)
                .frame(width: 400, height: 600)

            DeviceMockupView(image: placeholderImage, 
                             deviceType: .mac, 
                             backgroundColor: .purple 
                             // textOverlay: "Mac Preview Text", 
                             // textColor: .yellow, 
                             // textAlignment: .topLeading,
                             // fontName: "Futura",
                             // fontSize: 20
                             )
                .previewLayout(.sizeThatFits)
                .frame(width: 550, height: 450)
        }
    }
}

// Simple view for Mac stand
struct MacStandView: View {
    let frameWidth: CGFloat
    var body: some View {
        VStack(spacing: 0) {
            Rectangle() // Neck
                .fill(Color.gray.opacity(0.8))
                .frame(width: frameWidth * 0.15, height: 30)
            Path { path in // Base
                let baseWidth = frameWidth * 0.4
                let baseHeight: CGFloat = 10
                path.move(to: CGPoint(x: -baseWidth/2, y: 0))
                path.addLine(to: CGPoint(x: baseWidth/2, y: 0))
                path.addLine(to: CGPoint(x: baseWidth/2 - 5, y: baseHeight))
                path.addLine(to: CGPoint(x: -baseWidth/2 + 5, y: baseHeight))
                path.closeSubpath()
            }
            .fill(Color.gray.opacity(0.7))
            .frame(width: frameWidth * 0.4, height: 10)
            .shadow(color: Color.black.opacity(0.2), radius: 3, y: 2)
        }
    }
}
