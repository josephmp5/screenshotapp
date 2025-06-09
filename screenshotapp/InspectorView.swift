import SwiftUI

struct InspectorView: View {
    @ObservedObject var document: ScreenshotProjectDocument
    @Environment(\.undoManager) var undoManager
    
    @State private var selectedTextElementID: TextElementConfig.ID?

    // Local enum for Picker state management
    private enum PickerBackgroundType: Identifiable {
        case solid, gradient, image
        var id: Self { self }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Inspector")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.bottom, 10)

                // MARK: - Background Style Inspector
                Section {
                    Text("Background Style")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Picker("Type", selection: backgroundTypeBinding) {
                        Text("Solid Color").tag(PickerBackgroundType.solid)
                        Text("Gradient").tag(PickerBackgroundType.gradient)
                        Text("Image").tag(PickerBackgroundType.image)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.bottom, 5)

                    if let activePage = document.project.activePage {
                        // Use activePage.backgroundStyle.styleType which should come from ProjectModel.BackgroundStyle
                        switch activePage.backgroundStyle.styleType { 
                        case .solid:
                            ColorPicker("Color", selection: solidBackgroundColorBinding, supportsOpacity: true)
                        case .gradient:
                            // Pass the binding to the active page's gradient model
                            GradientEditorView(document: document, gradient: gradientModelBinding)
                        case .image:
                            ImageBackgroundEditorView(document: document)
                        // No default needed if ProjectModel.BackgroundStyle.StyleType is a frozen enum covering all cases
                        }
                    } else {
                        Text("No active page selected to edit background.")
                            .foregroundColor(.gray)
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

                    if let activePage = document.project.activePage {
                        if activePage.textElements.isEmpty {
                            Text("No text elements on this page.")
                                .foregroundColor(.gray)
                                .padding(.vertical)
                        } else {
                            List(selection: $selectedTextElementID) {
                                ForEach(activePage.textElements) { element in
                                    Text(element.text.prefix(30) + (element.text.count > 30 ? "..." : ""))
                                        .tag(element.id)
                                }
                                .onDelete(perform: deleteTextElements)
                            }
                            .frame(minHeight: 100, maxHeight: 300)
                        }

                        if let selectedID = selectedTextElementID,
                           let page = document.project.activePage, // Re-unwrap for safety, though activePage is checked above
                           let selectedElementIndex = page.textElements.firstIndex(where: { $0.id == selectedID }) {
                            
                            Text("Edit: \"\(page.textElements[selectedElementIndex].text.prefix(20))...\"")
                                .font(.headline)
                                .padding(.top)
                            
                            TextElementEditorView(document: document, element: Binding<TextElementConfig>(
                                get: {
                                    // Ensure page and index are still valid if textElements array could change elsewhere.
                                    // This specific 'page' variable is captured by the closure.
                                    if let freshPage = document.project.activePage, 
                                       freshPage.id == page.id, 
                                       selectedElementIndex < freshPage.textElements.count,
                                       freshPage.textElements[selectedElementIndex].id == selectedID {
                                        return freshPage.textElements[selectedElementIndex]
                                    }
                                    // Fallback or error handling if element disappeared
                                    // This might happen if another operation deleted the element and UI didn't refresh selection
                                    // For simplicity, returning a default or the original 'page' version if still valid.
                                    return page.textElements[selectedElementIndex] // Or handle error appropriately
                                },
                                set: { updatedElement in
                                    guard var pageToUpdate = document.project.activePage, pageToUpdate.id == page.id else { return }
                                    let oldElements = pageToUpdate.textElements
                                    if selectedElementIndex < pageToUpdate.textElements.count &&
                                       pageToUpdate.textElements[selectedElementIndex].id == selectedID {
                                        pageToUpdate.textElements[selectedElementIndex] = updatedElement
                                        document.project.activePage = pageToUpdate // This updates the project model
                                        
                                        let pageID = pageToUpdate.id
                                        undoManager?.registerUndo(withTarget: document, handler: { doc in
                                            if var targetPage = doc.project.pages.first(where: { $0.id == pageID }) {
                                                targetPage.textElements = oldElements
                                                doc.project.updatePage(targetPage)
                                            } else {
                                                // Fallback if page was deleted or ID changed, unlikely in this direct flow
                                            }
                                        })
                                        undoManager?.setActionName("Edit Text Element")
                                    }
                                }
                            ))
                            .id(selectedID) // Ensures TextElementEditorView redraws if selection changes
                        } else if !(document.project.activePage?.textElements.isEmpty ?? true) {
                             Text("Select a text element above to edit.")
                                .foregroundColor(.gray)
                                .padding(.vertical)
                        }
                    } else {
                        Text("No active page to display text elements.")
                            .foregroundColor(.gray)
                            .padding(.vertical)
                    }
                }
                Spacer()
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Bindings for Background

    private var solidBackgroundColorBinding: Binding<Color> {
        Binding<Color>(
            get: {
                guard let activePage = document.project.activePage,
                      case .solid(let codableColor) = activePage.backgroundStyle else {
                    return .gray // Fallback color
                }
                return codableColor.color
            },
            set: { newColor in
                guard var activePage = document.project.activePage else { return }
                let oldStyle = activePage.backgroundStyle
                let newSolidStyle = BackgroundStyle.solid(CodableColor(color: newColor))
                
                // Only update and register undo if the style actually changes
                if !oldStyle.isEffectivelyEqual(to: newSolidStyle) {
                    activePage.backgroundStyle = newSolidStyle
                    document.project.activePage = activePage // Update the project
                    
                    let pageID = activePage.id
                    undoManager?.registerUndo(withTarget: document, handler: { doc in
                        if var targetPage = doc.project.pages.first(where: { $0.id == pageID }) {
                            targetPage.backgroundStyle = oldStyle
                            doc.project.updatePage(targetPage)
                        }
                    })
                    undoManager?.setActionName("Change Background Color")
                }
            }
        )
    }

    private var gradientModelBinding: Binding<GradientModel> {
        Binding<GradientModel>(
            get: {
                guard let activePage = document.project.activePage,
                      case .gradient(let model) = activePage.backgroundStyle else {
                    // Return a default gradient if not available or wrong type
                    return GradientModel(colors: [CodableColor(color: .gray)], startPoint: .init(unitPoint: .top), endPoint: .init(unitPoint: .bottom))
                }
                return model
            },
            set: { newModel in
                guard var activePage = document.project.activePage else { return }
                let oldStyle = activePage.backgroundStyle
                let newGradientStyle = BackgroundStyle.gradient(newModel)

                // Assuming GradientModel is Equatable or has a way to check for changes
                // For simplicity, we update if the type is already gradient or if we are setting it.
                // GradientEditorView might handle its own fine-grained undo for internal changes.
                // This binding's undo is for changing TO this gradient model from something else or replacing it entirely.
                if !oldStyle.isEffectivelyEqual(to: newGradientStyle) { // Requires BackgroundStyle.isEffectivelyEqual
                    activePage.backgroundStyle = newGradientStyle
                    document.project.activePage = activePage

                    let pageID = activePage.id
                    undoManager?.registerUndo(withTarget: document, handler: { doc in
                        if var targetPage = doc.project.pages.first(where: { $0.id == pageID }) {
                            targetPage.backgroundStyle = oldStyle
                            doc.project.updatePage(targetPage)
                        }
                    })
                    undoManager?.setActionName("Change Gradient")
                }
            }
        )
    }
    
    private var backgroundTypeBinding: Binding<PickerBackgroundType> {
        Binding(
            get: {
                guard let activePage = document.project.activePage else { return .solid }
                // Map from ProjectModel.BackgroundStyle.StyleType to local PickerBackgroundType
                switch activePage.backgroundStyle.styleType {
                case .solid: return .solid
                case .gradient: return .gradient
                case .image: return .image
                // No default needed if ProjectModel.BackgroundStyle.StyleType is frozen and covers all cases
                }
            },
            set: { newPickerType in
                guard var activePage = document.project.activePage else { return }
                let oldStyle = activePage.backgroundStyle
                var newBackgroundStyle: BackgroundStyle? = nil

                switch newPickerType {
                case .solid:
                    if !oldStyle.isSolid {
                        newBackgroundStyle = .solid(CodableColor(color: .gray))
                    }
                case .gradient:
                    if !oldStyle.isGradient {
                        let baseColor = oldStyle.solidColor ?? (oldStyle.imageModel?.averageColor ?? CodableColor(color: .blue))
                        newBackgroundStyle = .gradient(GradientModel(
                            colors: [baseColor, CodableColor(color: baseColor.color.opacity(0.5))],
                            startPoint: .init(unitPoint: .topLeading), endPoint: .init(unitPoint: .bottomTrailing)
                        ))
                    }
                case .image:
                    if !oldStyle.isImage {
                        newBackgroundStyle = .image(ImageBackgroundModel()) // Placeholder, ImageBackgroundEditorView handles selection
                    }
                }

                if let newStyle = newBackgroundStyle {
                    activePage.backgroundStyle = newStyle
                    document.project.activePage = activePage
                    
                    let pageID = activePage.id
                    undoManager?.registerUndo(withTarget: document, handler: { doc in
                        if var targetPage = doc.project.pages.first(where: { $0.id == pageID }) {
                            targetPage.backgroundStyle = oldStyle
                            doc.project.updatePage(targetPage)
                        }
                    })
                    undoManager?.setActionName("Change Background Type")
                }
            }
        )
    }

    // MARK: - Text Element Actions

    private func addTextElement() {
        guard var activePage = document.project.activePage else { return }
        let pageID = activePage.id
        let oldElements = activePage.textElements
        
        let newElement = TextElementConfig(text: "New Text", positionRatio: CGPoint(x: 0.5, y: 0.5)) // Default to center
        activePage.textElements.append(newElement)
        document.project.activePage = activePage
        selectedTextElementID = newElement.id // Select the new element
        
        undoManager?.registerUndo(withTarget: document, handler: { doc in
            if var targetPage = doc.project.pages.first(where: { $0.id == pageID }) {
                targetPage.textElements = oldElements
                doc.project.updatePage(targetPage)
                // If the new element was selected, and now it's gone, deselect.
                // This might be complex if selection could change due to other reasons.
                // if self.selectedTextElementID == newElement.id { self.selectedTextElementID = nil }
            }
        })
        undoManager?.setActionName("Add Text Element")
    }

    private func deleteTextElements(at offsets: IndexSet) {
        guard var activePage = document.project.activePage else { return }
        let pageID = activePage.id
        let oldElements = activePage.textElements
        
        let idsToDelete = Set(offsets.map { activePage.textElements[$0].id })
        
        activePage.textElements.remove(atOffsets: offsets)
        document.project.activePage = activePage
        
        undoManager?.registerUndo(withTarget: document, handler: { doc in
            if var targetPage = doc.project.pages.first(where: { $0.id == pageID }) {
                targetPage.textElements = oldElements
                doc.project.updatePage(targetPage)
            }
        })
        undoManager?.setActionName("Delete Text Element(s)")
        
        if let currentSelectedID = selectedTextElementID, idsToDelete.contains(currentSelectedID) {
            selectedTextElementID = nil
        }
    }

    private func moveTextElement(up: Bool) {
        guard var activePage = document.project.activePage, 
              let selectedID = selectedTextElementID,
              let currentIndex = activePage.textElements.firstIndex(where: { $0.id == selectedID }) else { return }
        
        let pageID = activePage.id
        let targetIndex = up ? currentIndex - 1 : currentIndex + 1
        guard targetIndex >= 0 && targetIndex < activePage.textElements.count else { return }
        
        let oldElements = activePage.textElements
        activePage.textElements.swapAt(currentIndex, targetIndex)
        document.project.activePage = activePage
        
        undoManager?.registerUndo(withTarget: document, handler: { doc in
            if var targetPage = doc.project.pages.first(where: { $0.id == pageID }) {
                targetPage.textElements = oldElements
                doc.project.updatePage(targetPage)
            }
        })
        undoManager?.setActionName(up ? "Move Text Up" : "Move Text Down")
    }

    private func canMoveElement(up: Bool) -> Bool {
        guard let activePage = document.project.activePage, 
              let selectedID = selectedTextElementID,
              let currentIndex = activePage.textElements.firstIndex(where: { $0.id == selectedID }) else { return false }
        
        if up {
            return currentIndex > 0
        } else {
            return currentIndex < activePage.textElements.count - 1
        }
    }
}

struct InspectorView_Previews: PreviewProvider {
    static var previews: some View {
        let document = ScreenshotProjectDocument()
        
        // Create a sample page
        var samplePage = ScreenshotPage(name: "Preview Page")
        
        // Setup background style for the sample page
        samplePage.backgroundStyle = .gradient(GradientModel(
            colors: [CodableColor(color: .blue), CodableColor(color: .purple)],
            startPoint: .init(unitPoint: .top),
            endPoint: .init(unitPoint: .bottom)
        ))
        
        // Add text elements to the sample page
        samplePage.textElements.append(TextElementConfig(text: "Hello World"))
        samplePage.textElements.append(TextElementConfig(text: "Another Element"))
        
        // Add the page to the project and set it as active
        document.project.pages.append(samplePage)
        document.project.activePageID = samplePage.id
        
        return InspectorView(document: document)
            .frame(width: 320) // Typical inspector width
            .previewDisplayName("InspectorView with Document")
    }
}