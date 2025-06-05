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

// Main project data model
@MainActor
struct ProjectModel: Codable, Hashable {
    var id = UUID()
    var elements: [CanvasElement] = []
    var canvasBackgroundColor: CodableColor = CodableColor(color: .gray) // Default background
    // Add other project-wide settings like canvas size, zoom level, etc.
    
    // Swift will synthesize Equatable and Hashable conformance
    // as all members (id, elements, canvasBackgroundColor)
    // are Hashable and Equatable.
}
