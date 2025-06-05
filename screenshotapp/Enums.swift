import SwiftUI

enum DeviceType: String, CaseIterable, Identifiable {
    case iPhone = "iPhone"
    case iPad = "iPad"
    case mac = "Mac"
    // Add other devices as needed, e.g., Apple Watch, Vision Pro

    var id: String { self.rawValue }

    // You could add more device-specific metadata here if needed later,
    // for example, default aspect ratios, marketing names, etc.
}

// You can add other shared enums here as your project grows.
