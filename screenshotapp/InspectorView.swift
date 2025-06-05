import SwiftUI

struct InspectorView: View {
    @ObservedObject var document: ScreenshotProjectDocument
    // Later, we'll add @State for the currently selected element ID from the canvas
    // @State private var selectedElementID: CanvasElement.ID?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Inspector")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.bottom, 8)

                Text("Document ID: \(document.project.id.uuidString.prefix(8))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Divider()

                // Example: Displaying project-level properties
                Section("Project Settings") {
                    ColorPicker(
    "Canvas Background",
    selection: Binding<Color>(
        get: { document.project.canvasBackgroundColor.color },
        set: { newColor in document.project.canvasBackgroundColor = CodableColor(color: newColor) }
    ),
    supportsOpacity: true
)
.onChange(of: document.project.canvasBackgroundColor) { newValue in
                            // This direct change might bypass explicit undo registration if not careful.
                            // For complex properties, use functions that include undoManager.registerUndo.
                            // However, SwiftUI's @Binding with ReferenceFileDocument often handles this.
                            print("Background color changed via Inspector: \(newValue)")
                            // TODO: Ensure undo is registered if this doesn't happen automatically.
                        }
                    Text("Total Elements: \(document.project.elements.count)")
                }
                
                Divider()
                
                // Placeholder for selected element properties
                // if let selectedElement = document.project.elements.first(where: { $0.id == selectedElementID }) {
                //     Text("Selected: \(selectedElement.name)")
                //         .font(.headline)
                //     // TODO: Add controls for element properties (position, size, etc.)
                // } else {
                    Text("No element selected on canvas.")
                        .foregroundColor(.gray)
                // }

                Spacer()
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.7))
    }
}

struct InspectorView_Previews: PreviewProvider {
    static var previews: some View {
        let document = ScreenshotProjectDocument()
        InspectorView(document: document)
            .frame(width: 280)
            .previewDisplayName("InspectorView with Document")
    }
}

