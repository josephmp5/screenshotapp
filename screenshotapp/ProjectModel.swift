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

// Main project data model
@MainActor
struct ProjectModel: Codable, Hashable {
    var id = UUID()
    var elements: [CanvasElement] = [] // For future more complex, draggable elements
    var backgroundStyle: BackgroundStyle = .solid(CodableColor(color: .gray)) // Default background
    var textElements: [TextElementConfig] = [] // For template-driven text
    var importedImage: Data? = nil // For the user's screenshot
    var deviceFrame: DeviceFrameType = .iPhone15Pro // Default device frame
    var canvasSize: CGSize = CGSize(width: 1179, height: 2556) // Default to iPhone 15 Pro Max like size
    var deviceFrameOffset: CodableCGSize = .zero // Offset for device mockup dragging

    // Add other project-wide settings like zoom level, etc.
    
    // Swift will synthesize Equatable and Hashable conformance
    // as all members are Hashable and Equatable.
}
