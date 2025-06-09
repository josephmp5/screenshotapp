import SwiftUI

struct DeviceMockupView: View {
    let image: NSImage?
    let deviceType: DeviceType
    let backgroundColor: Color
    let targetHeight: CGFloat? // New parameter for scaling
    let imageScale: CGFloat
    let imageOffset: CGSize
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
                        .scaleEffect(imageScale)
                        .offset(imageOffset)
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: currentDeviceCornerRadius))
                        .frame(width: currentDeviceFrame.width, height: currentDeviceFrame.height)
                        .overlay(
                            RoundedRectangle(cornerRadius: currentDeviceCornerRadius)
                                .stroke(Color.black.opacity(0.7), lineWidth: currentDeviceBorderWidth)
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
                                        .frame(width: currentDeviceFrame.width * 0.35, height: currentDeviceFrame.height * 0.035)
                                        .offset(y: (-currentDeviceFrame.height / 2) + (currentDeviceFrame.height * 0.035 / 2) + currentDeviceBorderWidth + (currentDeviceFrame.height * 0.005)) // Adjusted offset slightly for scaling

                                    // Subtle side button hints (scaled)
                                    let buttonWidth = currentDeviceFrame.height * 0.007
                                    let shortButtonHeight = currentDeviceFrame.height * 0.05
                                    let mediumButtonHeight = currentDeviceFrame.height * 0.073
                                    let longButtonHeight = currentDeviceFrame.height * 0.122
                                    Capsule().fill(Color.black.opacity(0.3)).frame(width: buttonWidth, height: mediumButtonHeight).offset(x: -currentDeviceFrame.width/2 - buttonWidth/2, y: -currentDeviceFrame.height * 0.1)
                                    Capsule().fill(Color.black.opacity(0.3)).frame(width: buttonWidth, height: shortButtonHeight).offset(x: -currentDeviceFrame.width/2 - buttonWidth/2, y: -currentDeviceFrame.height * 0.1 - mediumButtonHeight * 0.85)
                                    Capsule().fill(Color.black.opacity(0.3)).frame(width: buttonWidth, height: longButtonHeight).offset(x: currentDeviceFrame.width/2 + buttonWidth/2, y: -currentDeviceFrame.height * 0.05)
                                }
                                
                                // iPad specific details
                                if deviceType == .iPad {
                                    // Front camera hint (scaled)
                                    let cameraDiameter = currentDeviceFrame.height * 0.0195
                                    Circle()
                                        .fill(Color.black.opacity(0.4))
                                        .frame(width: cameraDiameter, height: cameraDiameter)
                                        .offset(y: (-currentDeviceFrame.height / 2) + currentDeviceBorderWidth + cameraDiameter)
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
                MacStandView(frameWidth: currentDeviceFrame.width, frameHeight: currentDeviceFrame.height)
                    .offset(y: (currentDeviceFrame.height / 2) + (currentDeviceFrame.height * 0.05)) // Position below the Mac frame, scaled
            }
        }
        .edgesIgnoringSafeArea(.all) // Allow background to fill the entire ZStack area
    }

    // Default dimensions (used if targetHeight is nil)
    private var defaultDeviceFrame: (width: CGFloat, height: CGFloat) {
        switch deviceType {
        case .iPhone: return (200, 410)
        case .iPad: return (300, 420)
        case .mac: return (450, 280)
        }
    }

    private var currentDeviceFrame: (width: CGFloat, height: CGFloat) {
        if let th = targetHeight {
            let aspectRatio = defaultDeviceFrame.width / defaultDeviceFrame.height
            let scaledWidth = th * aspectRatio
            return (scaledWidth, th)
        }
        return defaultDeviceFrame
    }

    private var deviceFrame: (width: CGFloat, height: CGFloat) { // Keep for compatibility if anything still uses it, but prefer currentDeviceFrame
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

    private var currentDeviceCornerRadius: CGFloat {
        let baseHeight = defaultDeviceFrame.height
        let scaleFactor = currentDeviceFrame.height / baseHeight
        switch deviceType {
        case .iPhone: return 35 * scaleFactor
        case .iPad: return 25 * scaleFactor
        case .mac: return 10 * scaleFactor
        }
    }

    private var deviceCornerRadius: CGFloat { // Keep for compatibility
        switch deviceType {
        case .iPhone:
            return 35 // More pronounced rounding for modern iPhones
        case .iPad:
            return 25 // iPad Pro-like rounding
        case .mac:
            return 10
        }
    }

    private var currentDeviceBorderWidth: CGFloat {
        let baseHeight = defaultDeviceFrame.height
        let scaleFactor = currentDeviceFrame.height / baseHeight
        // Ensure border width doesn't become too small or too large, cap it.
        let scaledWidth = scaleFactor * (deviceType == .iPhone ? 6 : (deviceType == .iPad ? 8 : 15))
        return max(1.0, min(scaledWidth, currentDeviceFrame.height * 0.05)) // Min 1px, Max 5% of height
    }

    private var deviceBorderWidth: CGFloat { // Keep for compatibility
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
                             backgroundColor: .blue,
                             targetHeight: 410, // Example with targetHeight
                             imageScale: 1.0,
                             imageOffset: .zero
                             )
                .previewLayout(.sizeThatFits)
                .frame(width: 300, height: 600)
            
            DeviceMockupView(image: placeholderImage, 
                             deviceType: .iPad, 
                             backgroundColor: .green,
                             targetHeight: nil, // Example without targetHeight (uses default)
                             imageScale: 1.0,
                             imageOffset: .zero
                             )
                .previewLayout(.sizeThatFits)
                .frame(width: 400, height: 600)

            DeviceMockupView(image: placeholderImage, 
                             deviceType: .mac, 
                             backgroundColor: .purple,
                             targetHeight: 280,
                             imageScale: 1.0,
                             imageOffset: .zero
                             )
                .previewLayout(.sizeThatFits)
                .frame(width: 550, height: 450)
            
            // Example of a scaled up iPhone for export testing
            DeviceMockupView(image: placeholderImage,
                             deviceType: .iPhone,
                             backgroundColor: .gray,
                             targetHeight: 1000, // Significantly larger target height
                             imageScale: 1.0,
                             imageOffset: .zero
            )
            .previewLayout(.fixed(width: 500, height: 1200))

        }
    }
}

// Simple view for Mac stand
struct MacStandView: View {
    let frameWidth: CGFloat
    let frameHeight: CGFloat // Added to help scale stand elements if needed
    var body: some View {
        VStack(spacing: 0) {
            let neckHeight = frameHeight * 0.07 // Scale neck height
            let neckWidth = frameWidth * 0.15
            let basePlateHeight = frameHeight * 0.024 // Scale base plate height
            let basePlateWidth = frameWidth * 0.4

            Rectangle() // Neck
                .fill(Color.gray.opacity(0.8))
                .frame(width: neckWidth, height: neckHeight)
            Path { path in // Base
                let taper = basePlateHeight * 0.5 // How much the base tapers
                path.move(to: CGPoint(x: -basePlateWidth/2, y: 0))
                path.addLine(to: CGPoint(x: basePlateWidth/2, y: 0))
                path.addLine(to: CGPoint(x: basePlateWidth/2 - taper, y: basePlateHeight))
                path.addLine(to: CGPoint(x: -basePlateWidth/2 + taper, y: basePlateHeight))
                path.closeSubpath()
            }
            .fill(Color.gray.opacity(0.7))
            .frame(width: basePlateWidth, height: basePlateHeight)
            .shadow(color: Color.black.opacity(0.2), radius: 3, y: 2)
        }
    }
}
