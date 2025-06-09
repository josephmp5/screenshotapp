import SwiftUI

struct AppScreenshotTemplate: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var textElements: [TextElementConfig] = []
    var backgroundStyle: BackgroundStyle = .solid(CodableColor(color: .blue))
    var deviceFrame: DeviceFrameConfig = DeviceFrameConfig(deviceType: .iPhone15Pro, offset: .zero)
    var canvasSize: CodableCGSize? = nil

    init(id: UUID = UUID(), name: String, textElements: [TextElementConfig] = [], backgroundStyle: BackgroundStyle = .solid(CodableColor(color: .blue)), deviceFrame: DeviceFrameConfig, canvasSize: CodableCGSize? = nil) {
        self.id = id
        self.name = name
        self.textElements = textElements
        self.backgroundStyle = backgroundStyle
        self.deviceFrame = deviceFrame
        self.canvasSize = canvasSize
    }
}

struct DeviceFrameConfig: Codable, Hashable {
    var deviceType: DeviceFrameType
    var offset: CGPoint

    init(deviceType: DeviceFrameType, offset: CGPoint = .zero) {
        self.deviceType = deviceType
        self.offset = offset
    }
}

// Important: Ensure that the following types are defined and accessible:
// - TextElementConfig (likely in ProjectModel.swift or its own file)
// - BackgroundStyle (likely in ProjectModel.swift or Enums.swift)
// - CodableColor (likely in ProjectModel.swift or a utility file)
// - CodableCGSize (likely in ProjectModel.swift or a utility file)
// - DeviceFrameType (likely in Enums.swift)
// - CGPoint (from SwiftUI/CoreGraphics)
