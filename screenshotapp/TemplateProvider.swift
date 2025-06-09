import SwiftUI

class TemplateProvider {
    // Static array of templates
    static var templates: [AppScreenshotTemplate] = [
        AppScreenshotTemplate(name: "Simple Blue iPhone", deviceFrame: DeviceFrameConfig(deviceType: .iPhone15Pro, offset: .zero)),
        AppScreenshotTemplate(name: "Green iPad Landscape", deviceFrame: DeviceFrameConfig(deviceType: .iPadPro12_9, offset: .zero), canvasSize: CodableCGSize(size: CGSize(width: 1366, height: 1024))),
        AppScreenshotTemplate(name: "Basic Mac", deviceFrame: DeviceFrameConfig(deviceType: .macBookPro16, offset: .zero))
    ]

    // Optional: If you need a method to get by ID, though direct filtering of the static array is also common.
    static func template(withId id: UUID) -> AppScreenshotTemplate? {
        return templates.first { $0.id == id }
    }
}
