import SwiftUI

struct GradientEditorView: View {
    @ObservedObject var document: ScreenshotProjectDocument
    @Environment(\.undoManager) var undoManager
    @Binding var gradient: GradientModel

    // Predefined UnitPoints for pickers
    private let commonUnitPoints: [NamedUnitPoint] = [
        NamedUnitPoint(name: "Top Leading", point: .topLeading),
        NamedUnitPoint(name: "Top", point: .top),
        NamedUnitPoint(name: "Top Trailing", point: .topTrailing),
        NamedUnitPoint(name: "Leading", point: .leading),
        NamedUnitPoint(name: "Center", point: .center),
        NamedUnitPoint(name: "Trailing", point: .trailing),
        NamedUnitPoint(name: "Bottom Leading", point: .bottomLeading),
        NamedUnitPoint(name: "Bottom", point: .bottom),
        NamedUnitPoint(name: "Bottom Trailing", point: .bottomTrailing)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Gradient Colors")
                .font(.headline)

            ForEach(gradient.colors.indices, id: \.self) { index in
                HStack {
                    ColorPicker("Stop \(index + 1)", selection: Binding(
                        get: { gradient.colors[index].color },
                        set: { newColor in
                            updateColor(at: index, to: newColor)
                        }
                    ), supportsOpacity: true)
                    
                    Spacer()
                    
                    if gradient.colors.count > 2 { // Minimum 2 colors for a gradient
                        Button {
                            removeColor(at: index)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Button {
                addColor()
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Color Stop")
                }
            }
            .disabled(gradient.colors.count >= 10) // Limit to 10 stops for simplicity

            Divider().padding(.vertical, 5)

            Text("Gradient Direction")
                .font(.headline)
            
            Picker("Start Point", selection: Binding(
                get: { gradient.startPoint.unitPoint },
                set: { newUnitPoint in
                    updateStartPoint(to: newUnitPoint)
                }
            )) {
                ForEach(commonUnitPoints) { namedPoint in
                    Text(namedPoint.name).tag(namedPoint.point)
                }
            }

            Picker("End Point", selection: Binding(
                get: { gradient.endPoint.unitPoint },
                set: { newUnitPoint in
                    updateEndPoint(to: newUnitPoint)
                }
            )) {
                ForEach(commonUnitPoints) { namedPoint in
                    Text(namedPoint.name).tag(namedPoint.point)
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }

    // MARK: - Undoable Actions
    private func updateColor(at index: Int, to newColor: Color) {
        let oldGradient = self.gradient
        var newGradient = oldGradient
        newGradient.colors[index] = CodableColor(color: newColor)
        
        self.gradient = newGradient
        registerUndo(oldGradient: oldGradient, newGradient: newGradient, actionName: "Change Gradient Color Stop")
    }

    private func addColor() {
        let oldGradient = self.gradient
        var newGradient = oldGradient
        let lastColor = newGradient.colors.last?.color ?? .white
        newGradient.colors.append(CodableColor(color: lastColor.opacity(0.8))) // Add a slightly varied color
        
        self.gradient = newGradient
        registerUndo(oldGradient: oldGradient, newGradient: newGradient, actionName: "Add Gradient Color Stop")
    }

    private func removeColor(at index: Int) {
        let oldGradient = self.gradient
        var newGradient = oldGradient
        newGradient.colors.remove(at: index)
        
        self.gradient = newGradient
        registerUndo(oldGradient: oldGradient, newGradient: newGradient, actionName: "Remove Gradient Color Stop")
    }

    private func updateStartPoint(to newUnitPoint: UnitPoint) {
        let oldGradient = self.gradient
        var newGradient = oldGradient
        newGradient.startPoint = CodableUnitPoint(unitPoint: newUnitPoint)
        
        self.gradient = newGradient
        registerUndo(oldGradient: oldGradient, newGradient: newGradient, actionName: "Change Gradient Start Point")
    }

    private func updateEndPoint(to newUnitPoint: UnitPoint) {
        let oldGradient = self.gradient
        var newGradient = oldGradient
        newGradient.endPoint = CodableUnitPoint(unitPoint: newUnitPoint)
        
        self.gradient = newGradient
        registerUndo(oldGradient: oldGradient, newGradient: newGradient, actionName: "Change Gradient End Point")
    }
    
    private func registerUndo(oldGradient: GradientModel, newGradient: GradientModel, actionName: String) {
        // This assumes the binding change itself might not be directly undoable
        // or that we want to group changes to the document's backgroundStyle.
        let oldBackgroundStyle = document.project.backgroundStyle
        
        // Update the document's project directly, as the @Binding might be to a temporary copy
        // or we want to ensure the document's state is the source of truth for undo.
        document.project.backgroundStyle = .gradient(newGradient)
        
        undoManager?.registerUndo(withTarget: document, handler: { doc in
            doc.project.backgroundStyle = oldBackgroundStyle // Revert to the entire old style
            // If the binding was to a direct part of the document, this might be redundant
            // or could conflict. For complex nested bindings, it's often safer to manage
            // undo at the document level with whole-struct changes or specific setters.
        })
        undoManager?.setActionName(actionName)
    }
}

// Helper struct for Picker
struct NamedUnitPoint: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let point: UnitPoint
    
    static func == (lhs: NamedUnitPoint, rhs: NamedUnitPoint) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// Preview for GradientEditorView
struct GradientEditorView_Previews: PreviewProvider {
    struct PreviewWrapper: View {
        @State var gradient = GradientModel(
            colors: [CodableColor(color: .blue), CodableColor(color: .purple), CodableColor(color: .pink)],
            startPoint: CodableUnitPoint(unitPoint: .topLeading),
            endPoint: CodableUnitPoint(unitPoint: .bottomTrailing)
        )
        
        // Create a dummy document for preview context
        @StateObject var previewDocument = ScreenshotProjectDocument()

        var body: some View {
            // Initialize document's background style for context in undo
            let _ = previewDocument.project.backgroundStyle = .gradient(gradient)
            
            GradientEditorView(document: previewDocument, gradient: $gradient)
                .padding()
        }
    }

    static var previews: some View {
        PreviewWrapper()
            .frame(width: 300)
    }
}
