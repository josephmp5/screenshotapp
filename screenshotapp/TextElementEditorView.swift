import SwiftUI

struct TextElementEditorView: View {
    @Binding var element: TextElementConfig

    private let availableFontNames: [String] = [
        "System Font", "Helvetica Neue", "Arial", "Times New Roman", "Courier New", "Georgia", "Verdana", "Avenir Next"
    ]
    
    private let textAlignmentCases: [CodableTextAlignment] = [.leading, .center, .trailing]
    private let frameAlignmentCases: [CodableAlignment] = [
        .topLeading, .top, .topTrailing,
        .leading, .center, .trailing,
        .bottomLeading, .bottom, .bottomTrailing
    ]

    var body: some View {
        Form {
            Section(header: Text("Content & Style")) {
                TextEditor(text: $element.text)
                    .frame(minHeight: 80)
                    .border(Color.secondary.opacity(0.5), width: 0.5)
                
                Picker("Font", selection: $element.fontName) {
                    ForEach(availableFontNames, id: \.self) { fontName in
                        Text(fontName).tag(fontName)
                    }
                }
                
                Stepper("Size: \(element.fontSize, specifier: "%.0f")", value: $element.fontSize, in: 8...288, step: 1)
                
                ColorPicker("Text Color", selection: binding(for: \.textColor), supportsOpacity: true)
            }
            
            Section(header: Text("Layout & Position")) {
                Picker("Text Alignment", selection: $element.textAlignment) {
                    ForEach(textAlignmentCases, id: \.self) { alignment in
                        Text(alignment.description.capitalized).tag(alignment)
                    }
                }
                
                Picker("Frame Alignment", selection: $element.frameAlignment) {
                    ForEach(frameAlignmentCases, id: \.self) { alignment in
                        Text(alignment.description.capitalized).tag(alignment)
                    }
                }
                
                VStack(alignment: .leading) {
                    Text("Position X: \(element.positionRatio.x, specifier: "%.2f")")
                    Slider(value: binding(for: \.x, in: \.positionRatio), in: 0...1)
                }
                
                VStack(alignment: .leading) {
                    Text("Position Y: \(element.positionRatio.y, specifier: "%.2f")")
                    Slider(value: binding(for: \.y, in: \.positionRatio), in: 0...1)
                }
            }
            
            Section(header: Text("Effects")) {
                VStack(alignment: .leading) {
                    Text("Rotation: \(element.rotationAngle, specifier: "%.0f")°")
                    Slider(value: $element.rotationAngle, in: -180...180, step: 1)
                }
                
                Stepper("Scale: \(element.scale, specifier: "%.2f")x", value: $element.scale, in: 0.1...5.0, step: 0.05)
                
                Divider().padding(.vertical, 5)
                
                Group {
                    Text("Shadow")
                        .font(.caption).foregroundColor(.secondary)
                    ColorPicker("Color", selection: binding(for: \.shadowColor), supportsOpacity: true)
                    HStack {
                        Text("Opacity: \(element.shadowOpacity, specifier: "%.2f")")
                        Slider(value: $element.shadowOpacity, in: 0...1)
                    }
                    Stepper("Radius: \(element.shadowRadius, specifier: "%.1f")", value: $element.shadowRadius, in: 0...50, step: 0.5)
                    Stepper("Offset X: \(element.shadowOffset.width, specifier: "%.0f")", value: binding(for: \.width, in: \.shadowOffset), in: -50...50, step: 1)
                    Stepper("Offset Y: \(element.shadowOffset.height, specifier: "%.0f")", value: binding(for: \.height, in: \.shadowOffset), in: -50...50, step: 1)
                }
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Binding Helpers

    /// Creates a binding to a `CodableColor`'s underlying `Color`.
    private func binding(for keyPath: WritableKeyPath<TextElementConfig, CodableColor>) -> Binding<Color> {
        Binding<Color>(
            get: { self.element[keyPath: keyPath].color },
            set: { self.element[keyPath: keyPath] = CodableColor(color: $0) }
        )
    }
    
    /// Creates a binding to a `CGPoint`'s `x` or `y` component.
    private func binding(for pointComponent: WritableKeyPath<CGPoint, CGFloat>, in keyPath: WritableKeyPath<TextElementConfig, CGPoint>) -> Binding<CGFloat> {
        Binding<CGFloat>(
            get: { self.element[keyPath: keyPath][keyPath: pointComponent] },
            set: { self.element[keyPath: keyPath][keyPath: pointComponent] = $0 }
        )
    }

    /// Creates a binding to a `CGSize`'s `width` or `height` component.
    private func binding(for sizeComponent: WritableKeyPath<CGSize, CGFloat>, in keyPath: WritableKeyPath<TextElementConfig, CGSize>) -> Binding<CGFloat> {
        Binding<CGFloat>(
            get: { self.element[keyPath: keyPath][keyPath: sizeComponent] },
            set: { self.element[keyPath: keyPath][keyPath: sizeComponent] = $0 }
        )
    }
}

struct TextElementEditorView_Previews: PreviewProvider {
    static var previews: some View {
        // Use a stateful wrapper to provide a binding to a sample element.
        StatefulPreviewWrapper(TextElementConfig.preview) { elementBinding in
            TextElementEditorView(element: elementBinding)
        }
        .padding()
        .frame(width: 350)
    }
}
