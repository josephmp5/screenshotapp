import SwiftUI
import CoreGraphics // For CGPoint, CGSize

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
        self.shadowRadius = shadowRadius
        self.shadowOffset = shadowOffset
    }
}

/// Enum for different device frame mockups.
enum DeviceFrameType: String, CaseIterable, Identifiable, Codable, Hashable {
    // Map DeviceFrameType to DeviceType for use in DeviceMockupView
    var deviceType: DeviceType {
        switch self {
        case .iPhone15Pro, .iPhone15: return .iPhone
        case .iPadPro12_9, .iPadAir: return .iPad
        case .macBookPro16: return .mac
        case .appleWatchUltra: return .mac // <-- Replace with .watch if you add DeviceType.watch
        }
    }
    // Allow initializing DeviceFrameType from DeviceType (chooses a default frame for each type)
    init(deviceType: DeviceType) {
        switch deviceType {
        case .iPhone: self = .iPhone15Pro
        case .iPad: self = .iPadPro12_9
        case .mac: self = .macBookPro16
        }
    }
    case iPhone15Pro = "iPhone 15 Pro"
    case iPhone15 = "iPhone 15"
    case iPadPro12_9 = "iPad Pro 12.9\""
    case iPadAir = "iPad Air"
    case macBookPro16 = "MacBook Pro 16\""
    case appleWatchUltra = "Apple Watch Ultra"
    // Add more devices as needed
    // NOTE: Extend the mapping above if you add more DeviceFrameType or DeviceType cases.

    var id: String { self.rawValue }

    var displayName: String {
        self.rawValue
    }
    
    // Placeholder for actual frame asset names or properties
    var frameAssetName: String? {
        switch self {
        case .iPhone15Pro: return "iphone_15_pro_frame"
        // ... other assets
        default: return nil
        }
    }
}

// MARK: - Screenshot Page Definition

struct ScreenshotPage: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String? // Optional user-defined name for the page
    var importedImage: Data?
    var textElements: [TextElementConfig] = []
    var backgroundStyle: BackgroundStyle = .solid(CodableColor(color: .gray)) // Default background

    // New properties for imported image scale and offset
    var imageScale: CGFloat = 1.0
    var imageOffset: CodableCGSize = .zero // Using CodableCGSize for consistency for a new page
    var deviceFrameType: DeviceFrameType = .iPhone15Pro // Default device for a new page
    var deviceFrameOffset: CodableCGSize = .zero
    var canvasSize: CodableCGSize // Automatically set in init based on deviceFrameType
    // var scale: CGFloat = 1.0 // Future: Zoom level for this page
    // var watermark: WatermarkConfig? = nil // Future: Watermark for this page
    var elements: [CanvasElement] = [] // Future: Draggable elements specific to this page

    mutating func updateCanvasSizeToDefault() {
        self.canvasSize = ScreenshotPage.defaultCanvasSize(for: self.deviceFrameType)
    }

    init(id: UUID = UUID(), name: String? = nil, importedImage: Data? = nil, deviceFrameType: DeviceFrameType = .iPhone15Pro) {
        self.id = id
        self.name = name
        self.importedImage = importedImage
        self.deviceFrameType = deviceFrameType
        self.canvasSize = ScreenshotPage.defaultCanvasSize(for: deviceFrameType)
        // Other properties like textElements, backgroundStyle, etc., use their default initial values
    }

    // Helper to get default canvas size (in points) for a device.
    // These are example values and should be verified or made more comprehensive.
    static func defaultCanvasSize(for device: DeviceFrameType) -> CodableCGSize {
        switch device.deviceType { // Uses the .deviceType mapping from DeviceFrameType
        case .iPhone:
            return CodableCGSize(size: CGSize(width: 393, height: 852)) // e.g., iPhone 15 Pro (points)
        case .iPad:
            return CodableCGSize(size: CGSize(width: 1024, height: 1366)) // e.g., iPad Pro 12.9-inch (points)
        case .mac:
            return CodableCGSize(size: CGSize(width: 1728, height: 1117)) // e.g., MacBook Pro 16-inch (scaled points)
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
