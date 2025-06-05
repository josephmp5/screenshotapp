import SwiftUI

// Define the structure for an App Screenshot Template
struct AppScreenshotTemplate: Identifiable {
    let id = UUID()
    var name: String
    var deviceType: DeviceType
    var backgroundColor: Color
    var textOverlay: String
    var textColor: Color
    var textAlignment: Alignment // For text overlay position on the mockup
    var fontName: String
    var fontSize: CGFloat
    // Add other properties like specific device frame style, etc. later

    // Example: A simple initializer
    init(name: String, deviceType: DeviceType, backgroundColor: Color, textOverlay: String, textColor: Color = .white, textAlignment: Alignment = .bottom, fontName: String = "System Font", fontSize: CGFloat = 18) {
        self.name = name
        self.deviceType = deviceType
        self.backgroundColor = backgroundColor
        self.textOverlay = textOverlay
        self.textColor = textColor
        self.textAlignment = textAlignment
        self.fontName = fontName
        self.fontSize = fontSize
    }
}

// Create an array of predefined templates (Phase 1: 5-10 initial templates)
struct TemplateProvider {
    static var templates: [AppScreenshotTemplate] = [
        AppScreenshotTemplate(name: "Classic Blue iPhone", 
                              deviceType: .iPhone, 
                              backgroundColor: .blue, 
                              textOverlay: "Feature Highlight",
                              textColor: .white,
                              textAlignment: .bottom,
                              fontName: "Helvetica Neue",
                              fontSize: 20),
        AppScreenshotTemplate(name: "Modern Dark iPad", 
                              deviceType: .iPad, 
                              backgroundColor: Color(white: 0.1), 
                              textOverlay: "Immersive Experience",
                              textColor: .gray,
                              textAlignment: .center,
                              fontName: "Avenir Next",
                              fontSize: 22),
        AppScreenshotTemplate(name: "Green Tech Mac", 
                              deviceType: .mac, 
                              backgroundColor: .green.opacity(0.7), 
                              textOverlay: "Powerful & Intuitive",
                              textColor: .black,
                              textAlignment: .topLeading,
                              fontName: "San Francisco", // System font alias
                              fontSize: 18),
        AppScreenshotTemplate(name: "Minimalist iPhone Light", 
                              deviceType: .iPhone, 
                              backgroundColor: Color(white: 0.95), 
                              textOverlay: "Clean & Simple UI",
                              textColor: .black,
                              textAlignment: .bottomTrailing,
                              fontName: "Gill Sans",
                              fontSize: 16),
        AppScreenshotTemplate(name: "Vibrant iPad Showcase", 
                              deviceType: .iPad, 
                              backgroundColor: .orange, 
                              textOverlay: "Discover What's New",
                              textColor: .white,
                              textAlignment: .bottom,
                              fontName: "Futura",
                              fontSize: 24)
    ]
}
