import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

// Helper struct to make SwiftUI.Color Codable
struct CodableColor: Codable, Hashable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    #if os(macOS)
    init(color: Color) {
        // NSColor(color) can be problematic for non-RGBA colors.
        // This initialization is simplified; robust handling might require more complex logic
        // or restricting user color choices to those easily convertible.
        let nsColor = NSColor(color)
        // Ensure the color is in an RGB-compatible color space
        guard let rgbColor = nsColor.usingColorSpace(.sRGB) else {
            // Fallback for colors not convertible to sRGB (e.g., pattern, catalog colors)
            self.red = 0; self.green = 0; self.blue = 0; self.alpha = 1; // Default to black
            print("Warning: Could not convert color to sRGB. Defaulting to black.")
            return
        }
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        rgbColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.red = Double(r)
        self.green = Double(g)
        self.blue = Double(b)
        self.alpha = Double(a)
    }

    var nsColor: NSColor {
        NSColor(srgbRed: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(alpha))
    }
    #else // iOS/watchOS/tvOS
    init(color: Color) {
        let uiColor = UIColor(color)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.red = Double(r)
        self.green = Double(g)
        self.blue = Double(b)
        self.alpha = Double(a)
    }
    var uiColor: UIColor {
        UIColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(alpha))
    }
    #endif

    var color: Color {
        get {
            #if os(macOS)
            Color(nsColor)
            #else
            Color(uiColor)
            #endif
        }
        set {
            #if os(macOS)
            let nsColor = NSColor(newValue)
            guard let rgbColor = nsColor.usingColorSpace(.sRGB) else {
                // Fallback for colors not convertible to sRGB
                self.red = 0; self.green = 0; self.blue = 0; self.alpha = 1; // Default to black
                print("Warning: Could not convert color to sRGB during set. Defaulting to black.")
                return
            }
            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0
            var a: CGFloat = 0
            rgbColor.getRed(&r, green: &g, blue: &b, alpha: &a)
            self.red = Double(r)
            self.green = Double(g)
            self.blue = Double(b)
            self.alpha = Double(a)
            #else // iOS/watchOS/tvOS
            let uiColor = UIColor(newValue)
            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0
            var a: CGFloat = 0
            uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
            self.red = Double(r)
            self.green = Double(g)
            self.blue = Double(b)
            self.alpha = Double(a)
            #endif
        }
    }
    
    // Static common colors
    static let clear = CodableColor(color: .clear)
    static let black = CodableColor(color: .black)
    static let white = CodableColor(color: .white)
    static let primary = CodableColor(color: .primary)
    // Add other common colors as needed, e.g., .red, .blue, etc.

    // Conformance to Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(red)
        hasher.combine(green)
        hasher.combine(blue)
        hasher.combine(alpha)
    }

    static func == (lhs: CodableColor, rhs: CodableColor) -> Bool {
        return lhs.red == rhs.red &&
               lhs.green == rhs.green &&
               lhs.blue == rhs.blue &&
               lhs.alpha == rhs.alpha
    }
}
