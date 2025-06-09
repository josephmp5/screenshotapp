import SwiftUI

struct TextElementEditorView: View {
    @ObservedObject var document: ScreenshotProjectDocument
    @Environment(\.undoManager) var undoManager
    @Binding var element: TextElementConfig // This binding is to the element in InspectorView's list
    
    // Predefined font names for the picker
    private let availableFontNames: [String] = [
        "System Font", "Helvetica Neue", "Arial", "Times New Roman", "Courier New", "Georgia", "Verdana", "Avenir Next"
    ]
    
    // Predefined alignments
    private let textAlignmentCases: [CodableTextAlignment] = [.leading, .center, .trailing]
    private let frameAlignmentCases: [CodableAlignment] = [
        .topLeading, .top, .topTrailing,
        .leading, .center, .trailing,
        .bottomLeading, .bottom, .bottomTrailing
    ]

    var body: some View {
        Form {
            Section(header: Text("Content & Style")) {
                TextEditor(text: makeBinding(for: \.text, actionName: "Edit Text Content"))
                    .frame(minHeight: 80)
                    .border(Color.secondary.opacity(0.5), width: 0.5)
                
                Picker("Font", selection: makeBinding(for: \.fontName, actionName: "Change Font")) {
                    ForEach(availableFontNames, id: \.self) { fontName in
                        Text(fontName).tag(fontName)
                    }
                }
                
                Stepper("Size: \(element.fontSize, specifier: "%.0f")",
                        value: makeBinding(for: \.fontSize, actionName: "Change Font Size"),
                        in: 8...288, step: 1)
                
                ColorPicker("Text Color", selection: makeBinding(for: \.color, mappedTo: \.textColor, actionName: "Change Text Color"), supportsOpacity: true)
            }
            
            Section(header: Text("Layout & Position")) {
                Picker("Text Alignment", selection: makeBinding(for: \.textAlignment, actionName: "Change Text Alignment")) {
                    ForEach(textAlignmentCases, id: \.self) { alignment in
                        Text(alignment.description.capitalized).tag(alignment)
                    }
                }
                
                Picker("Frame Alignment", selection: makeBinding(for: \.frameAlignment, actionName: "Change Frame Alignment")) {
                    ForEach(frameAlignmentCases, id: \.self) { alignment in
                        Text(alignment.description.capitalized).tag(alignment)
                    }
                }
                
                VStack(alignment: .leading) {
                    Text("Position X: \(element.positionRatio.x, specifier: "%.2f")")
                    Slider(value: makeBinding(for: \.x, mappedTo: \.positionRatio, actionName: "Change Position X"), in: 0...1)
                }
                
                VStack(alignment: .leading) {
                    Text("Position Y: \(element.positionRatio.y, specifier: "%.2f")")
                    Slider(value: makeBinding(for: \.y, mappedTo: \.positionRatio, actionName: "Change Position Y"), in: 0...1)
                }
            }
            
            Section(header: Text("Frame Styling")) {
                Group {
                    Text("Padding")
                        .font(.caption).foregroundColor(.secondary)
                    Stepper("Top: \(element.padding.top, specifier: "%.0f")", value: makeBinding(for: \.top, mappedTo: \.padding, actionName: "Change Padding Top"), in: 0...100, step: 1)
                    Stepper("Leading: \(element.padding.leading, specifier: "%.0f")", value: makeBinding(for: \.leading, mappedTo: \.padding, actionName: "Change Padding Leading"), in: 0...100, step: 1)
                    Stepper("Bottom: \(element.padding.bottom, specifier: "%.0f")", value: makeBinding(for: \.bottom, mappedTo: \.padding, actionName: "Change Padding Bottom"), in: 0...100, step: 1)
                    Stepper("Trailing: \(element.padding.trailing, specifier: "%.0f")", value: makeBinding(for: \.trailing, mappedTo: \.padding, actionName: "Change Padding Trailing"), in: 0...100, step: 1)
                }
                
                Divider()
                
                Group {
                    Text("Background")
                        .font(.caption).foregroundColor(.secondary)
                    ColorPicker("Color", selection: makeBinding(for: \.color, mappedTo: \.backgroundColor, actionName: "Change Element Background Color"), supportsOpacity: true)
                    HStack {
                        Text("Opacity: \(element.backgroundOpacity, specifier: "%.2f")")
                        Slider(value: makeBinding(for: \.backgroundOpacity, actionName: "Change Element Background Opacity"), in: 0...1)
                    }
                }
                
                Divider()
                
                Group {
                    Text("Border")
                        .font(.caption).foregroundColor(.secondary)
                    ColorPicker("Color", selection: makeBinding(for: \.color, mappedTo: \.borderColor, actionName: "Change Element Border Color"), supportsOpacity: true)
                    Stepper("Width: \(element.borderWidth, specifier: "%.1f")", value: makeBinding(for: \.borderWidth, actionName: "Change Element Border Width"), in: 0...20, step: 0.5)
                }
            }
            
            Section(header: Text("Effects")) {
                VStack(alignment: .leading) {
                    Text("Rotation: \(element.rotationAngle, specifier: "%.0f")°")
                    Slider(value: makeBinding(for: \.rotationAngle, actionName: "Change Rotation"), in: -180...180, step: 1)
                }
                
                Stepper("Scale: \(element.scale, specifier: "%.2f")x",
                        value: makeBinding(for: \.scale, actionName: "Change Scale"),
                        in: 0.1...5.0, step: 0.05)
                
                Divider().padding(.vertical, 5)
                
                Group {
                    Text("Shadow")
                        .font(.caption).foregroundColor(.secondary)
                    ColorPicker("Color", selection: makeBinding(for: \.color, mappedTo: \.shadowColor, actionName: "Change Shadow Color"), supportsOpacity: true)
                    HStack {
                        Text("Opacity: \(element.shadowOpacity, specifier: "%.2f")")
                        Slider(value: makeBinding(for: \.shadowOpacity, actionName: "Change Shadow Opacity"), in: 0...1)
                    }
                    Stepper("Radius: \(element.shadowRadius, specifier: "%.1f")", value: makeBinding(for: \.shadowRadius, actionName: "Change Shadow Radius"), in: 0...50, step: 0.5)
                    Stepper("Offset X: \(element.shadowOffset.width, specifier: "%.0f")", value: makeBinding(for: \.width, mappedTo: \.shadowOffset, actionName: "Change Shadow Offset X"), in: -50...50, step: 1)
                    Stepper("Offset Y: \(element.shadowOffset.height, specifier: "%.0f")", value: makeBinding(for: \.height, mappedTo: \.shadowOffset, actionName: "Change Shadow Offset Y"), in: -50...50, step: 1)
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }

    // MARK: - Helper for Creating Bindings with Undo

    private func makeBinding<Value>(for keyPath: WritableKeyPath<TextElementConfig, Value>, actionName: String) -> Binding<Value> where Value: Equatable {
        Binding(
            get: { self.element[keyPath: keyPath] },
            set: { newValue in
                let oldValueInState = self.element[keyPath: keyPath]
                if oldValueInState != newValue {
                    let oldElementFromDoc = self.element // This is the element from the @Binding, reflecting current state in document
                    
                    // Create a mutable copy to apply the change, then update the @Binding
                    var modifiedElement = self.element 
                    modifiedElement[keyPath: keyPath] = newValue
                    self.element = modifiedElement // This updates the @Binding, which InspectorView owns

                    // Now, reflect this change in the document's activePage and register undo
                    guard var activePage = document.project.activePage else { return }
                    let pageID = activePage.id

                    if let indexInPage = activePage.textElements.firstIndex(where: { $0.id == oldElementFromDoc.id }) {
                        activePage.textElements[indexInPage] = modifiedElement
                        document.project.activePage = activePage
                        
                        undoManager?.registerUndo(withTarget: document, handler: { doc in
                            if var targetPage = doc.project.pages.first(where: { $0.id == pageID }),
                               let idx = targetPage.textElements.firstIndex(where: { $0.id == oldElementFromDoc.id }) {
                                targetPage.textElements[idx] = oldElementFromDoc // Revert to the original state of the element
                                doc.project.updatePage(targetPage)
                            }
                        })
                        undoManager?.setActionName(actionName)
                    }
                }
            }
        )
    }

    private func makeBinding<Value, OuterValue>(for innerKeyPath: WritableKeyPath<OuterValue, Value>, mappedTo outerKeyPath: WritableKeyPath<TextElementConfig, OuterValue>, actionName: String) -> Binding<Value> where Value: Equatable, OuterValue: Equatable {
        Binding(
            get: { self.element[keyPath: outerKeyPath][keyPath: innerKeyPath] },
            set: { newValue in
                let oldOuterValueInState = self.element[keyPath: outerKeyPath]
                var newOuterValue = oldOuterValueInState
                newOuterValue[keyPath: innerKeyPath] = newValue

                if oldOuterValueInState != newOuterValue {
                    let oldElementFromDoc = self.element
                    
                    var modifiedElement = self.element
                    modifiedElement[keyPath: outerKeyPath] = newOuterValue
                    self.element = modifiedElement // Update @Binding

                    guard var activePage = document.project.activePage else { return }
                    let pageID = activePage.id

                    if let indexInPage = activePage.textElements.firstIndex(where: { $0.id == oldElementFromDoc.id }) {
                        activePage.textElements[indexInPage] = modifiedElement
                        document.project.activePage = activePage
                        
                        undoManager?.registerUndo(withTarget: document, handler: { doc in
                            if var targetPage = doc.project.pages.first(where: { $0.id == pageID }),
                               let idx = targetPage.textElements.firstIndex(where: { $0.id == oldElementFromDoc.id }) {
                                targetPage.textElements[idx] = oldElementFromDoc
                                doc.project.updatePage(targetPage)
                            }
                        })
                        undoManager?.setActionName(actionName)
                    }
                }
            }
        )
    }
}

struct TextElementEditorView_Previews: PreviewProvider {
    struct PreviewWrapper: View {
        @State var element: TextElementConfig
        @StateObject var previewDocument: ScreenshotProjectDocument

        // Initializer to set up the document and element for the preview
        init() {
            let doc = ScreenshotProjectDocument()
            var samplePage = ScreenshotPage(name: "Preview Page")
            var initialElement = TextElementConfig(
                text: "Sample Text",
                fontName: "Helvetica Neue",
                fontSize: 32,
                textColor: CodableColor(color: .black),
                textAlignment: .center,
                frameAlignment: .center,
                positionRatio: CGPoint(x: 0.5, y: 0.5)
            )
            samplePage.textElements.append(initialElement)
            doc.project.pages.append(samplePage)
            doc.project.activePageID = samplePage.id
            
            _previewDocument = StateObject(wrappedValue: doc)
            // Initialize the @State 'element' with the one from the document's active page
            // This ensures the binding starts with the correct reference for the preview.
            if let active = doc.project.activePage, let firstElement = active.textElements.first {
                _element = State(initialValue: firstElement)
            } else {
                // Fallback if no element, though the setup above should ensure one exists
                _element = State(initialValue: initialElement) 
            }
        }

        var body: some View {
            TextElementEditorView(document: previewDocument, element: $element)
        }
    }

    static var previews: some View {
        PreviewWrapper()
            .frame(width: 350)
            .padding()
    }
}
