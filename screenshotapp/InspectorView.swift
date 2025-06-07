import SwiftUI

struct InspectorView: View {
    @ObservedObject var document: ScreenshotProjectDocument
    @Environment(\.undoManager) var undoManager
    
    @State private var selectedTextElementID: TextElementConfig.ID?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) { // Increased spacing
                Text("Inspector")
                    .font(.title) // Larger title
                    .fontWeight(.bold)
                    .padding(.bottom, 10)

                // MARK: - Background Style Inspector
                Section {
                    Text("Background Style")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    // Picker for background type (Solid/Gradient)
                    Picker("Type", selection: backgroundTypeBinding) {
                        Text("Solid Color").tag(BackgroundType.solid)
                        Text("Gradient").tag(BackgroundType.gradient)
                        Text("Image").tag(BackgroundType.image)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.bottom, 5)

                    switch document.project.backgroundStyle.styleType {
                    case .solid:
                        ColorPicker("Color", selection: solidBackgroundColorBinding, supportsOpacity: true)
                    case .gradient:
                        GradientEditorView(document: document, gradient: gradientModelBinding)
                    case .image:
                        ImageBackgroundEditorView(document: document)
                    }
                }
                .padding(.bottom)
                
                Divider()

                // MARK: - Text Elements Inspector
                Section {
                    HStack {
                        Text("Text Elements")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Spacer()
                        Button(action: { moveTextElement(up: true) }) {
                            Image(systemName: "arrow.up.circle.fill")
                        }
                        .help("Move selected element up")
                        .disabled(selectedTextElementID == nil || !canMoveElement(up: true))
                        
                        Button(action: { moveTextElement(up: false) }) {
                            Image(systemName: "arrow.down.circle.fill")
                        }
                        .help("Move selected element down")
                        .disabled(selectedTextElementID == nil || !canMoveElement(up: false))
                        
                        Button(action: addTextElement) {
                            Image(systemName: "plus.circle.fill")
                        }
                        .help("Add new text element")
                    }

                    if document.project.textElements.isEmpty {
                        Text("No text elements in this project.")
                            .foregroundColor(.gray)
                            .padding(.vertical)
                    } else {
                        List(selection: $selectedTextElementID) {
                            ForEach(document.project.textElements) { element in
                                Text(element.text.prefix(30) + (element.text.count > 30 ? "..." : ""))
                                    .tag(element.id)
                            }
                            .onDelete(perform: deleteTextElements)
                        }
                        .frame(minHeight: 100, maxHeight: 300) // Constrain list height
                    }

                    // Editor for selected text element
                    if let selectedID = selectedTextElementID,
                       let selectedElementIndex = document.project.textElements.firstIndex(where: { $0.id == selectedID }) {
                        
                        Text("Edit: \"\(document.project.textElements[selectedElementIndex].text.prefix(20))...\"")
                            .font(.headline)
                            .padding(.top)
                        
                        // Integrate TextElementEditorView
                        // The binding ensures that changes made by TextElementEditorView
                        // (which handles its own undo registration for property changes via its makeBinding methods)
                        // are reflected in the document's array of text elements.
                        TextElementEditorView(document: document, element: Binding<TextElementConfig>(
                            get: {
                                // selectedElementIndex is derived from selectedID and validated before this point.
                                // This assumes selectedElementIndex is valid and points to the correct element.
                                document.project.textElements[selectedElementIndex]
                            },
                            set: { updatedElement in
                                // TextElementEditorView's internal `makeBinding` functions are responsible
                                // for updating the specific element within `document.project.textElements`
                                // and registering the undo action. This `set` block is called when
                                // TextElementEditorView's `@Binding var element` is modified.
                                // We ensure the document's array reflects this change.
                                if selectedElementIndex < document.project.textElements.count &&
                                   document.project.textElements[selectedElementIndex].id == selectedID {
                                    document.project.textElements[selectedElementIndex] = updatedElement
                                }
                            }
                        ))
                        .id(selectedID) // Ensure the editor view redraws if the selected element changes
                    } else if !document.project.textElements.isEmpty {
                         Text("Select a text element above to edit.")
                            .foregroundColor(.gray)
                            .padding(.vertical)
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // .background(Color(NSColor.controlBackgroundColor).opacity(0.7)) // Removed for cleaner default look
    }

    // MARK: - Bindings and Helper Logic for Background

    private var gradientModelBinding: Binding<GradientModel> {
        Binding<GradientModel>(
            get: {
                if case .gradient(let model) = document.project.backgroundStyle {
                    return model
                }
                // This fallback should ideally not be reached if the UI logic is correct
                // and GradientEditorView is only shown when the style is indeed .gradient.
                assertionFailure("gradientModelBinding.get accessed when backgroundStyle is not .gradient")
                return GradientModel(colors: [CodableColor(color: .gray)], startPoint: .init(unitPoint: .top), endPoint: .init(unitPoint: .bottom))
            },
            set: { newModel in
                // The GradientEditorView is responsible for updating the document.project.backgroundStyle
                // and registering undo actions via its internal methods (e.g., updateColor, addColor).
                // Those methods modify the 'gradient' @Binding within GradientEditorView, which in turn
                // calls this 'set' block.
                // Since GradientEditorView's registerUndo method already updates
                // document.project.backgroundStyle = .gradient(newModelFromEditor), this set block
                // here doesn't need to do it again. It ensures the binding contract is fulfilled.
                // If document.project.backgroundStyle was not updated by GradientEditorView, this would be the place:
                // if case .gradient(_) = document.project.backgroundStyle { // Ensure it's still a gradient
                //     document.project.backgroundStyle = .gradient(newModel)
                // }
            }
        )
    }

    
    private enum BackgroundType {
        case solid, gradient, image
    }

    private var backgroundTypeBinding: Binding<BackgroundType> {
        Binding(
            get: {
                    switch document.project.backgroundStyle.styleType {
                    case .solid: return .solid
                    case .gradient: return .gradient
                    case .image: return .image
                    }
                },
            set: { newType in
                let oldStyle = document.project.backgroundStyle
                var newBackgroundStyle: BackgroundStyle = oldStyle
                
                switch newType {
                case .solid:
                    if !oldStyle.isSolid { // If changing from gradient to solid
                        newBackgroundStyle = .solid(CodableColor(color: .gray)) // Default solid
                    }
                case .gradient:
                    if oldStyle.styleType == .solid { // If changing from solid to gradient
                        // Default gradient or try to convert solid color
                        let solidColor = oldStyle.solidColor ?? CodableColor(color: .blue)
                        newBackgroundStyle = .gradient(GradientModel(
                            colors: [solidColor, CodableColor(color: solidColor.color.opacity(0.5))],
                            startPoint: .init(unitPoint: .topLeading),
                            endPoint: .init(unitPoint: .bottomTrailing)
                        ))
                    }
                case .image:
                    if oldStyle.styleType != .image { // If changing to image
                        newBackgroundStyle = .image(ImageBackgroundModel(imageData: nil, tilingMode: .aspectFill, opacity: 1.0))
                    }
                }
                
                if !areBackgroundStylesEffectivelyEqual(oldStyle, newBackgroundStyle) {
                    document.project.backgroundStyle = newBackgroundStyle
                    undoManager?.registerUndo(withTarget: document, handler: { doc in
                        doc.project.backgroundStyle = oldStyle
                    })
                    undoManager?.setActionName("Change Background Type")
                }
            }
        )
    }

    private var solidBackgroundColorBinding: Binding<Color> {
        Binding(
            get: {
                if case .solid(let codableColor) = document.project.backgroundStyle {
                    return codableColor.color
                }
                return .gray // Should not happen if UI is consistent
            },
            set: { newColor in
                let oldStyle = document.project.backgroundStyle
                let newSolidStyle = BackgroundStyle.solid(CodableColor(color: newColor))
                
                if !areBackgroundStylesEffectivelyEqual(oldStyle, newSolidStyle) {
                    document.project.backgroundStyle = newSolidStyle
                    undoManager?.registerUndo(withTarget: document, handler: { doc in
                        doc.project.backgroundStyle = oldStyle
                    })
                    undoManager?.setActionName("Change Background Color")
                }
            }
        )
    }
    
    // Helper to compare background styles for undo registration
    // This is basic; a full Equatable conformance on BackgroundStyle would be better.
    private func areBackgroundStylesEffectivelyEqual(_ style1: BackgroundStyle, _ style2: BackgroundStyle) -> Bool {
        switch (style1, style2) {
        case (.solid(let color1), .solid(let color2)):
            return color1 == color2 // Assumes CodableColor is Equatable
        case (.gradient(let model1), .gradient(let model2)):
            return model1 == model2 // Assumes GradientModel is Equatable
        case (.image(let model1), .image(let model2)):
            return model1 == model2 // Assumes ImageBackgroundModel is Equatable
        default:
            return false
        }
    }

    // MARK: - Text Element Actions

    private func canMoveElement(up: Bool) -> Bool {
        guard let selectedID = selectedTextElementID,
              let currentIndex = document.project.textElements.firstIndex(where: { $0.id == selectedID }) else {
            return false
        }
        if up {
            return currentIndex > 0
        } else {
            return currentIndex < document.project.textElements.count - 1
        }
    }

    private func moveTextElement(up: Bool) {
        guard let selectedID = selectedTextElementID,
              let currentIndex = document.project.textElements.firstIndex(where: { $0.id == selectedID }) else {
            return
        }

        let targetIndex = up ? currentIndex - 1 : currentIndex + 1

        guard targetIndex >= 0 && targetIndex < document.project.textElements.count else {
            return // Should be prevented by button's disabled state, but good to check
        }

        let oldElements = document.project.textElements
        var newElements = oldElements
        newElements.swapAt(currentIndex, targetIndex)
        
        document.project.textElements = newElements
        // The selection ID remains the same, List should handle it.

        undoManager?.registerUndo(withTarget: document, handler: { doc in
            doc.project.textElements = oldElements
        })
    }

    private func addTextElement() {
        let oldElements = document.project.textElements
        let newElement = TextElementConfig(
            text: "New Text",
            fontName: "System Font",
            fontSize: 24,
            textColor: CodableColor(color: .white),
            textAlignment: .center,
            frameAlignment: .center,
            positionRatio: CGPoint(x: 0.5, y: 0.5) // Default to center
        )
        document.project.textElements.append(newElement)
        selectedTextElementID = newElement.id // Select the new element
        
        undoManager?.registerUndo(withTarget: document, handler: { doc in
            doc.project.textElements = oldElements
        })
        undoManager?.setActionName("Add Text Element")
    }

    private func deleteTextElements(at offsets: IndexSet) {
        let oldElements = document.project.textElements
        var newElements = oldElements
        
        // Check if the currently selected element is being deleted
        let idsToDelete = Set(offsets.map { oldElements[$0].id })
        if let selectedID = selectedTextElementID, idsToDelete.contains(selectedID) {
            selectedTextElementID = nil // Deselect if it's deleted
        }
        
        newElements.remove(atOffsets: offsets)
        document.project.textElements = newElements
        
        undoManager?.registerUndo(withTarget: document, handler: { doc in
            doc.project.textElements = oldElements
            // Potentially re-select if needed, though for simplicity, we might not here
        })
        undoManager?.setActionName("Delete Text Element(s)")
    }
} // Closing brace for struct InspectorView

    // MARK: - BackgroundStyle Extension
extension BackgroundStyle {
    // Helper to determine type, useful for pickers etc.
    // This StyleType enum is local to the InspectorView's needs.
    // The main BackgroundStyle enum in ProjectModel.swift will have the actual cases.
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
        case .image: return .image // This relies on the .image case being in the main enum
        @unknown default:
            // This handles future cases if any are added to BackgroundStyle in ProjectModel.swift
            // and ensures the switch is exhaustive.
            // Fallback for UI picker if main enum isn't updated or an unexpected case appears.
            print("Warning: Unhandled or not-yet-defined BackgroundStyle case in styleType. Defaulting to solid for UI.")
            return .solid 
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
        if case .image = self { return true } // Relies on .image in main enum
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
        if case .image(let model) = self { return model } // Relies on .image in main enum
        return nil
    }
}

// It should ideally be in a more general utility file or near CodableUnitPoint definition.
extension UnitPoint {
    var debugDescription: String {
        switch self {
        case .top: return "Top"
        case .bottom: return "Bottom"
        case .leading: return "Leading"
        case .trailing: return "Trailing"
        case .topLeading: return "Top Leading"
        case .topTrailing: return "Top Trailing"
        case .bottomLeading: return "Bottom Leading"
        case .bottomTrailing: return "Bottom Trailing"
        case .center: return "Center"
        default: return "(\(String(format: "%.2f", x)), \(String(format: "%.2f", y)))"
        }
    }
}


struct InspectorView_Previews: PreviewProvider {
    static var previews: some View {
        let document = ScreenshotProjectDocument()
        // Setup with a gradient for preview
        document.project.backgroundStyle = .gradient(GradientModel(
            colors: [CodableColor(color: .blue), CodableColor(color: .purple)],
            startPoint: .init(unitPoint: .top),
            endPoint: .init(unitPoint: .bottom)
        ))
        document.project.textElements.append(TextElementConfig(text: "Hello World"))
        document.project.textElements.append(TextElementConfig(text: "Another Element"))
        
        return InspectorView(document: document)
            .frame(width: 320) // Typical inspector width
            .previewDisplayName("InspectorView with Document")
    }
}