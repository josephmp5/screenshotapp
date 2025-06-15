import SwiftUI

struct TextElementView: View {
    let config: TextElementConfig
    var fontScaleFactor: CGFloat = 1.0 // Default to 1.0, can be overridden

    var body: some View {
        Text(config.text)
            .font(.custom(config.fontName, size: config.fontSize * fontScaleFactor))
            .foregroundColor(config.textColor.color)
            .rotationEffect(.degrees(config.rotationAngle))
    }
}
