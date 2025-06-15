import SwiftUI
import CoreGraphics // For CGPoint, CGSize

// MARK: - Device Definitions

// DeviceType defines the specific characteristics of a device model for rendering
enum DeviceType: String, CaseIterable, Identifiable, Codable, Hashable {
    case iPhone15Pro = "iPhone 15 Pro"
    case iPhone15ProMax = "iPhone 15 Pro Max"
    case iPadPro11 = "iPad Pro 11-inch"
    case iPadPro12_9 = "iPad Pro 12.9-inch"
    case macBookPro14 = "MacBook Pro 14-inch"
    case macBookPro16 = "MacBook Pro 16-inch"
    case iPhone16ProMax = "iPhone 16 Pro Max" // Added new device
    case custom = "Custom" // Represents no specific device frame or a passthrough

    var id: String { self.rawValue }

    var frameAssetName: String {
        switch self {
        case .iPhone15Pro: return "iPhone_15_Pro_Frame"
        case .iPhone15ProMax: return "iPhone_15_Pro_Max_Frame"
        case .iPadPro11: return "iPad_Pro_11_Frame"
        case .iPadPro12_9: return "iPad_Pro_12_9_Frame"
        case .macBookPro14: return "MacBook_Pro_14_Frame"
        case .macBookPro16: return "MacBook_Pro_16_Frame"
        case .iPhone16ProMax: return "iPhone_16_Pro_Max_Frame" // Added new device asset name
        case .custom: return "" // No asset for custom type
        }
    }

    // IMPORTANT: These CGRect values define the screen area within the frame asset (in pixels/points of the asset image).
    // (x, y, width, height) - YOU MUST UPDATE THESE WITH ACCURATE VALUES FOR YOUR ASSETS.
    var screenAreaPixels: CGRect {
        switch self {
        case .iPhone15Pro:    return CGRect(x: 88, y: 88, width: 1114, height: 2420)  // Placeholder
        case .iPhone15ProMax: return CGRect(x: 88, y: 88, width: 1215, height: 2632)  // Placeholder
        case .iPadPro11:      return CGRect(x: 50, y: 50, width: 734, height: 1094)  // Placeholder
        case .iPadPro12_9:    return CGRect(x: 60, y: 60, width: 904, height: 1246)  // Placeholder
        case .macBookPro14:   return CGRect(x: 40, y: 70, width: 1432, height: 892)  // Placeholder (accounts for notch area)
        case .macBookPro16:   return CGRect(x: 45, y: 75, width: 1638, height: 1027) // Placeholder (accounts for notch area)
        case .iPhone16ProMax: return CGRect(x: 90, y: 90, width: 1250, height: 2700)  // USER MUST UPDATE THIS PLACEHOLDER
        case .custom:         return .zero // No specific screen area for custom
        }
    }

    // IMPORTANT: This CGFloat is the corner radius for clipping the screenshot to match the device screen.
    // YOU MUST UPDATE THESE WITH ACCURATE VALUES FOR YOUR ASSETS.
    var screenCornerRadius: CGFloat {
        switch self {
        case .iPhone15Pro:    return 55.0  // Placeholder
        case .iPhone15ProMax: return 59.0  // Placeholder
        case .iPadPro11:      return 18.0  // Placeholder (iPads often have less pronounced rounding)
        case .iPadPro12_9:    return 18.0  // Placeholder
        case .macBookPro14:   return 12.0  // Placeholder (MacBooks might have slight rounding or be sharp)
        case .macBookPro16:   return 12.0  // Placeholder (MacBooks might have slight rounding or be sharp)
        case .iPhone16ProMax: return 60.0  // USER MUST UPDATE THIS PLACEHOLDER
        case .custom:         return 0.0   // No corner radius for custom
        }
    }
}

// DeviceFrameType is used in ScreenshotPage to select the desired device appearance.
// It maps to a DeviceType which holds the detailed rendering information.
enum DeviceFrameType: String, CaseIterable, Identifiable, Codable, Hashable {
    case iPhone15Pro = "iPhone 15 Pro"
    case iPhone15ProMax = "iPhone 15 Pro Max"
    case iPadPro11 = "iPad Pro 11-inch"
    case iPadPro12_9 = "iPad Pro 12.9-inch"
    case macBookPro14 = "MacBook Pro 14-inch"
    case macBookPro16 = "MacBook Pro 16-inch"
    case iPhone16ProMax = "iPhone 16 Pro Max" // Added new device frame type
    case custom = "Custom (No Frame)" // For screenshots without a device frame

    var id: String { self.rawValue }

    static var defaultDevice: DeviceFrameType {
        .iPhone15Pro // Default to iPhone 15 Pro
    }

    // This computed property provides the corresponding DeviceType instance.
    // CanvasView uses this to get frameAssetName, screenAreaPixels, etc.
    var deviceType: DeviceType {
        switch self {
        case .iPhone15Pro: return .iPhone15Pro
        case .iPhone15ProMax: return .iPhone15ProMax
        case .iPadPro11: return .iPadPro11
        case .iPadPro12_9: return .iPadPro12_9
        case .macBookPro14: return .macBookPro14
        case .macBookPro16: return .macBookPro16
        case .iPhone16ProMax: return .iPhone16ProMax // Added mapping for new device
        case .custom: return .custom // Map DeviceFrameType.custom to DeviceType.custom
        }
    }
}

// CGPoint and CGSize are already Codable and Hashable in Swift/CoreGraphics.
// Custom extensions for these are no longer needed and cause redeclaration errors.

// MARK: - Project Data Structures

// Represents a single element on the canvas
// This will be expanded significantly in later phases.
struct CanvasElement: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String = "Element" // Placeholder name
    var position: CGPoint = .zero // Placeholder position
    var size: CGSize = CGSize(width: 100, height: 100) // Placeholder size
    // Add more properties like type, content, styling, etc.

    // Swift will synthesize Equatable and Hashable conformance
}

// Helper for Codable CGSize - ensure this is defined. If it's elsewhere, this is fine.
// If not, it should be added, perhaps in a separate Utilities file or here if simple enough.
struct CodableCGSize: Codable, Hashable {
    var width: CGFloat
    var height: CGFloat

    init(size: CGSize) {
        self.width = size.width
        self.height = size.height
    }

    var cgSize: CGSize {
        CGSize(width: width, height: height)
    }

    static var zero: CodableCGSize {
        CodableCGSize(size: .zero)
    }
}

// MARK: - Background Style Definitions

/// Defines how an image background should be tiled or scaled.
enum ImageTilingMode: String, CaseIterable, Identifiable, Codable, Hashable {
    case stretch = "Stretch"      // Stretch to fill the bounds
    case tile = "Tile"          // Tile the image at its original size
    case aspectFit = "Aspect Fit" // Scale to fit within bounds, maintaining aspect ratio
    case aspectFill = "Aspect Fill" // Scale to fill bounds, maintaining aspect ratio (may crop)
    var id: String { self.rawValue }
}

/// Model for storing image background properties.
struct ImageBackgroundModel: Codable, Hashable {
    var imageData: Data?                // The actual image data
    var tilingMode: ImageTilingMode = .aspectFill // How the image is displayed
    var opacity: Double = 1.0           // Opacity of the image layer
    var averageColor: CodableColor?     // Optional average color of the image, can be computed
}

/// A Codable and Hashable wrapper for SwiftUI's UnitPoint.
struct CodableUnitPoint: Codable, Hashable {
    var x: CGFloat
    var y: CGFloat

    init(unitPoint: UnitPoint) {
        self.x = unitPoint.x
        self.y = unitPoint.y
    }

    var unitPoint: UnitPoint {
        UnitPoint(x: x, y: y)
    }

    // Common points for convenience, matching UnitPoint static members
    static let topLeading = CodableUnitPoint(unitPoint: .topLeading)
    static let top = CodableUnitPoint(unitPoint: .top)
    static let topTrailing = CodableUnitPoint(unitPoint: .topTrailing)
    static let leading = CodableUnitPoint(unitPoint: .leading)
    static let center = CodableUnitPoint(unitPoint: .center)
    static let trailing = CodableUnitPoint(unitPoint: .trailing)
    static let bottomLeading = CodableUnitPoint(unitPoint: .bottomLeading)
    static let bottom = CodableUnitPoint(unitPoint: .bottom)
    static let bottomTrailing = CodableUnitPoint(unitPoint: .bottomTrailing)
}

/// Model for storing gradient properties.
struct GradientModel: Codable, Hashable {
    var colors: [CodableColor] = [CodableColor(color: .blue), CodableColor(color: .green)]
    var startPoint: CodableUnitPoint = .top
    var endPoint: CodableUnitPoint = .bottom
}

/// Defines the style of the background for a screenshot project.
/// This enum is now the single source of truth for background style definitions.
enum BackgroundStyle: Codable, Hashable {
    case solid(CodableColor)
    case gradient(GradientModel)
    case image(ImageBackgroundModel)

    enum StyleType: String, CaseIterable, Identifiable {
        case solid = "Solid Color"
        case gradient = "Gradient"
        case image = "Image Background"
        var id: String { self.rawValue }
    }

    var styleType: StyleType {
        switch self {
        case .solid: return .solid
        case .gradient: return .gradient
        case .image: return .image
        }
    }

    var isSolid: Bool {
        if case .solid = self { return true }
        return false
    }

    var isGradient: Bool {
        if case .gradient = self { return true }
        return false
    }

    var isImage: Bool {
        if case .image = self { return true }
        return false
    }

    var solidColor: CodableColor? {
        if case .solid(let color) = self { return color }
        return nil
    }

    var gradientModel: GradientModel? {
        if case .gradient(let model) = self { return model }
        return nil
    }

    var imageModel: ImageBackgroundModel? {
        if case .image(let model) = self { return model }
        return nil
    }

    func isEffectivelyEqual(to other: BackgroundStyle) -> Bool {
        switch (self, other) {
        case (.solid(let color1), .solid(let color2)):
            return color1 == color2 // Assumes CodableColor is Equatable
        case (.gradient(let model1), .gradient(let model2)):
            return model1 == model2 // Assumes GradientModel is Equatable
        case (.image(let model1), .image(let model2)):
            // For images, you might want a more nuanced comparison
            // e.g., just comparing imageData might be too strict if other props change.
            // For now, direct equatability of ImageBackgroundModel (which includes imageData).
            return model1 == model2 // Assumes ImageBackgroundModel is Equatable
        default:
            return false // Different types are not equal
        }
    }
}

// MARK: - Text Element and Device Definitions

/// Codable and Hashable wrapper for SwiftUI.TextAlignment.
struct CodableTextAlignment: Codable, Hashable, CustomStringConvertible {
    let alignment: SwiftUI.TextAlignment

    init(_ alignment: SwiftUI.TextAlignment) {
        self.alignment = alignment
    }

    enum CodingKeys: String, CodingKey {
        case alignmentValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawValue = try container.decode(String.self, forKey: .alignmentValue)
        switch rawValue {
        case "leading": self.alignment = .leading
        case "center": self.alignment = .center
        case "trailing": self.alignment = .trailing
        default: throw DecodingError.dataCorruptedError(forKey: .alignmentValue, in: container, debugDescription: "Invalid TextAlignment value")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let rawValue: String
        switch alignment {
        case .leading: rawValue = "leading"
        case .center: rawValue = "center"
        case .trailing: rawValue = "trailing"
        @unknown default:
            rawValue = "center" // Fallback for unknown future cases
        }
        try container.encode(rawValue, forKey: .alignmentValue)
    }
    
    static let leading = CodableTextAlignment(.leading)
    static let center = CodableTextAlignment(.center)
    static let trailing = CodableTextAlignment(.trailing)
    
    var swiftUIAlignment: SwiftUI.TextAlignment { alignment }

    public var description: String {
        switch self.alignment {
        case .leading: return "Leading"
        case .center: return "Center"
        case .trailing: return "Trailing"
        @unknown default: return "Unknown"
        }
    }
}

/// Codable and Hashable wrapper for SwiftUI.Alignment.
struct CodableAlignment: Codable, Hashable, Equatable, CustomStringConvertible {
    let alignment: SwiftUI.Alignment

    init(_ alignment: SwiftUI.Alignment) {
        self.alignment = alignment
    }

    enum CodingKeys: String, CodingKey {
        case alignmentValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawValue = try container.decode(String.self, forKey: .alignmentValue)
        switch rawValue {
        case "topLeading": self.alignment = .topLeading
        case "top": self.alignment = .top
        case "topTrailing": self.alignment = .topTrailing
        case "leading": self.alignment = .leading
        case "center": self.alignment = .center
        case "trailing": self.alignment = .trailing
        case "bottomLeading": self.alignment = .bottomLeading
        case "bottom": self.alignment = .bottom
        case "bottomTrailing": self.alignment = .bottomTrailing
        default: throw DecodingError.dataCorruptedError(forKey: .alignmentValue, in: container, debugDescription: "Invalid Alignment value")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let rawValue: String
        switch alignment {
        case .topLeading: rawValue = "topLeading"
        case .top: rawValue = "top"
        case .topTrailing: rawValue = "topTrailing"
        case .leading: rawValue = "leading"
        case .center: rawValue = "center"
        case .trailing: rawValue = "trailing"
        case .bottomLeading: rawValue = "bottomLeading"
        case .bottom: rawValue = "bottom"
        case .bottomTrailing: rawValue = "bottomTrailing"
        default: rawValue = "center" // Fallback for unknown future cases
        }
        try container.encode(rawValue, forKey: .alignmentValue)
    }

    static let topLeading = CodableAlignment(.topLeading)
    static let top = CodableAlignment(.top)
    static let topTrailing = CodableAlignment(.topTrailing)
    static let leading = CodableAlignment(.leading)
    static let center = CodableAlignment(.center)
    static let trailing = CodableAlignment(.trailing)
    static let bottomLeading = CodableAlignment(.bottomLeading)
    static let bottom = CodableAlignment(.bottom)
    static let bottomTrailing = CodableAlignment(.bottomTrailing)
    
    var swiftUIAlignment: SwiftUI.Alignment { alignment }

    public var description: String {
        switch self.alignment {
        case .topLeading: return "Top Leading"
        case .top: return "Top"
        case .topTrailing: return "Top Trailing"
        case .leading: return "Leading"
        case .center: return "Center"
        case .trailing: return "Trailing"
        case .bottomLeading: return "Bottom Leading"
        case .bottom: return "Bottom"
        case .bottomTrailing: return "Bottom Trailing"
        default: return "Custom Alignment" // Handle potential custom alignments if any
        }
    }

    // Explicit Equatable conformance
    static func == (lhs: CodableAlignment, rhs: CodableAlignment) -> Bool {
        return lhs.alignment == rhs.alignment
    }

    // Explicit Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.description)
    }
}

/// Codable and Hashable wrapper for EdgeInsets.
struct CodableEdgeInsets: Codable, Hashable {
    var top: CGFloat
    var leading: CGFloat
    var bottom: CGFloat
    var trailing: CGFloat

    init(top: CGFloat = 0, leading: CGFloat = 0, bottom: CGFloat = 0, trailing: CGFloat = 0) {
        self.top = top
        self.leading = leading
        self.bottom = bottom
        self.trailing = trailing
    }

    init(edgeInsets: EdgeInsets) {
        self.top = edgeInsets.top
        self.leading = edgeInsets.leading
        self.bottom = edgeInsets.bottom
        self.trailing = edgeInsets.trailing
    }

    var edgeInsets: EdgeInsets {
        EdgeInsets(top: top, leading: leading, bottom: bottom, trailing: trailing)
    }
    
    static let zero = CodableEdgeInsets()
}

/// Configuration for a single text element on the canvas.
struct TextElementConfig: Identifiable, Codable, Hashable {
    var id = UUID()
    var text: String = "Sample Text"
    var fontName: String = "System Font"
    var fontSize: CGFloat = 24
    var textColor: CodableColor = CodableColor(color: .white)
    
    var textAlignment: CodableTextAlignment = .center
    var frameAlignment: CodableAlignment = .center
    
    var positionRatio: CGPoint = CGPoint(x: 0.5, y: 0.5) // Relative to canvas size
    var offsetPixels: CGSize = .zero // Additional pixel offset

    // Frame dimensions (optional, as ratios of canvas size)
    var frameWidthRatio: CGFloat? = nil
    var frameHeightRatio: CGFloat? = nil

    // Styling
    var padding: CodableEdgeInsets = .zero
    var backgroundColor: CodableColor = CodableColor(color: .clear)
    var backgroundOpacity: Double = 1.0
    var borderColor: CodableColor = CodableColor(color: .clear)
    var borderWidth: CGFloat = 0
    
    // Effects
    var rotationAngle: Double = 0 // Degrees
    var scale: CGFloat = 1.0
    var shadowColor: CodableColor = CodableColor(color: .clear)
    var shadowOpacity: Double = 0.0
    var shadowRadius: CGFloat = 0
    var shadowOffset: CGSize = .zero
    
    // Default initializer
    init(id: UUID = UUID(), text: String = "Sample Text", fontName: String = "System Font", fontSize: CGFloat = 24, textColor: CodableColor = CodableColor(color: .primary), textAlignment: CodableTextAlignment = .center, frameAlignment: CodableAlignment = .center, positionRatio: CGPoint = CGPoint(x: 0.5, y: 0.5), offsetPixels: CGSize = .zero, frameWidthRatio: CGFloat? = nil, frameHeightRatio: CGFloat? = nil, padding: CodableEdgeInsets = .zero, backgroundColor: CodableColor = .clear, backgroundOpacity: Double = 1.0, borderColor: CodableColor = .clear, borderWidth: CGFloat = 0, rotationAngle: Double = 0, scale: CGFloat = 1.0, shadowColor: CodableColor = .clear, shadowOpacity: Double = 0, shadowRadius: CGFloat = 0, shadowOffset: CGSize = .zero) {
        self.id = id
        self.text = text
        self.fontName = fontName
        self.fontSize = fontSize
        self.textColor = textColor
        self.textAlignment = textAlignment
        self.frameAlignment = frameAlignment
        self.positionRatio = positionRatio
        self.offsetPixels = offsetPixels
        self.frameWidthRatio = frameWidthRatio
        self.frameHeightRatio = frameHeightRatio
        self.padding = padding
        self.backgroundColor = backgroundColor
        self.backgroundOpacity = backgroundOpacity
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.rotationAngle = rotationAngle
        self.scale = scale
        self.shadowColor = shadowColor
        self.shadowOpacity = shadowOpacity
    }

    /// A sample instance for SwiftUI Previews.
    static var preview: TextElementConfig {
        TextElementConfig(
            text: "Hello, World!",
            fontName: "Helvetica Neue",
            fontSize: 48,
            textColor: CodableColor(color: .blue),
            textAlignment: .center,
            frameAlignment: .center,
            positionRatio: CGPoint(x: 0.5, y: 0.3),
            shadowColor: CodableColor(color: .black.opacity(0.3)),
            shadowOpacity: 1.0,
            shadowRadius: 5,
            shadowOffset: CGSize(width: 2, height: 2)
        )
    }
}

/// Enum for different device frame mockups.
// The DeviceFrameType enum (and DeviceType) are now defined at the top of this file.

// MARK: - Screenshot Page Definition

struct ScreenshotPage: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String? // Optional user-defined name for the page
    var importedImage: Data?
    var textElements: [TextElementConfig] = []
    var backgroundStyle: BackgroundStyle = .solid(CodableColor(color: .gray)) // Default background

    var deviceFrameType: DeviceFrameType = .iPhone15Pro // Default device for a new page
    var deviceFrameOffset: CodableCGSize = .zero
    var deviceScale: CGFloat = 1.0 // Scale factor for the device mockup on the canvas
    var canvasSize: CodableCGSize // Automatically set in init based on deviceFrameType
    // var scale: CGFloat = 1.0 // Future: Zoom level for this page
    // var watermark: WatermarkConfig? = nil // Future: Watermark for this page
    var elements: [CanvasElement] = [] // Future: Draggable elements specific to this page

    mutating func updateCanvasSizeToDefault() {
        self.canvasSize = ScreenshotPage.defaultCanvasSize(for: self.deviceFrameType)
    }

    init(id: UUID = UUID(), name: String? = nil, importedImage: Data? = nil, deviceFrameType: DeviceFrameType = .iPhone15Pro, deviceScale: CGFloat = 1.0) {
        self.id = id
        self.name = name
        self.importedImage = importedImage
        self.deviceFrameType = deviceFrameType
        self.deviceScale = deviceScale
        self.canvasSize = ScreenshotPage.defaultCanvasSize(for: deviceFrameType)
        // Other properties like textElements, backgroundStyle, etc., use their default initial values
    }

    // Helper to get default canvas size (in points) for a device.
    // These are example values and should be verified or made more comprehensive.
    static func defaultCanvasSize(for device: DeviceFrameType) -> CodableCGSize {
        switch device.deviceType {
        case .iPhone15Pro, .iPhone15ProMax:
            return CodableCGSize(size: CGSize(width: 393, height: 852)) // Default iPhone size (e.g., iPhone 15 Pro points)
        case .iPadPro11, .iPadPro12_9:
            return CodableCGSize(size: CGSize(width: 1024, height: 1366)) // Default iPad size (e.g., iPad Pro 12.9-inch points)
        case .macBookPro14, .macBookPro16:
            return CodableCGSize(size: CGSize(width: 1728, height: 1117)) // Default Mac size (e.g., MacBook Pro 16-inch scaled points)
        case .iPhone16ProMax:
            return CodableCGSize(size: CGSize(width: 430, height: 932)) // Default iPhone Pro Max size (e.g., iPhone 16 Pro Max points)
        case .custom:
            return CodableCGSize(size: CGSize(width: 1200, height: 900)) // Default size for custom/passthrough, adjust as needed
        // If you add more DeviceType cases, ensure they are handled here or in the @unknown default.
        @unknown default:
            // Fallback to a generic size or a common device like iPhone 15 Pro
            // This handles any future DeviceType cases not explicitly listed above.
            return CodableCGSize(size: CGSize(width: 393, height: 852))
        }
    }
}

// Main project data model
@MainActor
struct ProjectModel: Codable, Hashable {
    var id = UUID() // Project ID
    var pages: [ScreenshotPage] = []
    var activePageID: UUID? // ID of the currently active page

    // Example of a project-global setting (can be added if needed)
    // var projectGlobalTheme: String = "Default"

    init() {
        let initialPage = ScreenshotPage(name: "Page 1")
        self.pages = [initialPage]
        self.activePageID = initialPage.id
    }

    // Computed property to get/set the active page's data.
    // This provides a convenient way to interact with the active page.
    // In ProjectModel.swift

    // Ensure activePage setter updates the array
    // In ProjectModel.swift

    var activePage: ScreenshotPage? {
        get {
            // If activePageID is nil, and pages exist, return the first page.
            // If pages is empty, activePageID being nil means no active page.
            guard let currentActiveID = activePageID else { return pages.first }
            return pages.first(where: { $0.id == currentActiveID })
        }
        set {
            guard let newPageData = newValue else {
                // If trying to set activePage to nil (e.g. all pages deleted),
                // we might want to set activePageID to nil.
                // For now, if newPageData is nil, we'll just return.
                // Consider if activePageID should be cleared if pages array becomes empty.
                return
            }

            // Determine the ID of the page to update or identify as active.
            // If activePageID is already set, we use that.
            // Otherwise, we assume the newPageData.id is the one to make active.
            let targetID = self.activePageID ?? newPageData.id

            if let index = pages.firstIndex(where: { $0.id == targetID }) {
                pages[index] = newPageData // Update the page in the array
                if self.activePageID == nil { // If activePageID was initially nil
                    self.activePageID = targetID // Set it to the page we just updated
                }
            } else {
                // This means the targetID (either a previous activePageID or newPageData.id)
                // was not found in the pages array.
                // A setter should ideally not add new pages; that should be an explicit action.
                // If activePageID was nil and newPageData.id is not in pages,
                // this indicates a potential logic issue elsewhere (e.g., a page wasn't added before being set active).
                print("Error in ProjectModel.activePage.set: Page with ID \(targetID) not found in 'pages' array.")
            }
        }
    }

    mutating func updatePage(_ page: ScreenshotPage) {
        if let index = pages.firstIndex(where: { $0.id == page.id }) {
            pages[index] = page
        }
    }

    // Make sure ScreenshotPage has an updateCanvasSizeToDefault method:
    // In ScreenshotPage.swift
    // mutating func updateCanvasSizeToDefault(for deviceType: DeviceFrameType) {
    //     self.canvasSize = DeviceFrameType.defaultCanvasSize(for: deviceType)
    // }

    // And DeviceFrameType has a static method for default canvas size:
    // In ProjectModel.swift (or wherever DeviceFrameType is defined)
    // static func defaultCanvasSize(for deviceType: DeviceFrameType) -> CodableCGSize {
    //     switch deviceType {
    //         case .iPhone_15_Pro: return CodableCGSize(width: 1179, height: 2556) // Example
    //         // ... other cases
    //         default: return CodableCGSize(width: 1200, height: 900) // Generic default
    //     }
    // }
    
    // Function to add a new page (example)
    mutating func addNewPage(name: String? = nil, importedImage: Data? = nil, deviceFrameType: DeviceFrameType = .iPhone15Pro) {
        let newPage = ScreenshotPage(name: name ?? "Page \(pages.count + 1)", importedImage: importedImage, deviceFrameType: deviceFrameType)
        pages.append(newPage)
        activePageID = newPage.id // Optionally make the new page active
    }

    // Function to remove a page (example)
    mutating func removePage(withID id: UUID) {
        pages.removeAll { $0.id == id }
        // If the removed page was active, set a new active page (e.g., first page or nil)
        if activePageID == id {
            activePageID = pages.first?.id
        }
    }
}
