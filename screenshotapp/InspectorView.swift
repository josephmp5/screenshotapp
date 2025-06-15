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

    /// A binding to the currently selected text element, which handles undo management.
    /// When the value of this binding is set (i.e., when `TextElementEditorView` makes a change),
    /// it triggers a full, undoable update of the project model.
    private var selectedElementBinding: Binding<TextElementConfig>? {
        guard let selectedID = selectedTextElementID,
              let activePage = document.project.activePage,
              let elementIndex = activePage.textElements.firstIndex(where: { $0.id == selectedID })
        else {
            return nil
        }

        return Binding<TextElementConfig>(
            get: {
                // Re-fetch for safety, as the project is a struct and could have been replaced.
                if let refreshedPage = document.project.activePage,
                   refreshedPage.id == activePage.id,
                   elementIndex < refreshedPage.textElements.count {
                    return refreshedPage.textElements[elementIndex]
                }
                // Fallback to the last known good state if something went wrong.
                return activePage.textElements[elementIndex]
            },
            set: { updatedElement in
                var newProject = document.project
                guard var pageToUpdate = newProject.activePage,
                      let indexToUpdate = pageToUpdate.textElements.firstIndex(where: { $0.id == selectedID })
                else { return }

                pageToUpdate.textElements[indexToUpdate] = updatedElement
                newProject.updatePage(pageToUpdate)
                document.changeProjectModel(to: newProject, actionName: "Edit Text Element")
            }
        )
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

                                                if let elementBinding = selectedElementBinding {
                            Text("Edit: \"\(elementBinding.wrappedValue.text.prefix(20))...\"")
                                .font(.headline)
                                .padding(.top)
                            
                            TextElementEditorView(element: elementBinding)
                                .id(selectedTextElementID) // Ensures view redraws when selection changes
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
                var newProject = document.project
                guard var activePage = newProject.activePage else { return }
                
                let newSolidStyle = BackgroundStyle.solid(CodableColor(color: newColor))

                if !activePage.backgroundStyle.isEffectivelyEqual(to: newSolidStyle) {
                    activePage.backgroundStyle = newSolidStyle
                    newProject.updatePage(activePage)
                    document.changeProjectModel(to: newProject, actionName: "Change Background Color")
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
                var newProject = document.project
                guard var activePage = newProject.activePage else { return }
                
                let newGradientStyle = BackgroundStyle.gradient(newModel)

                if !activePage.backgroundStyle.isEffectivelyEqual(to: newGradientStyle) {
                    activePage.backgroundStyle = newGradientStyle
                    newProject.updatePage(activePage)
                    document.changeProjectModel(to: newProject, actionName: "Change Gradient")
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
                // Create a mutable copy of the project model to avoid direct mutation.
                var newProject = document.project
                guard var activePage = newProject.activePage else { return }

                let oldStyle = activePage.backgroundStyle
                var newBackgroundStyle: BackgroundStyle? = nil

                // Determine the new style, only if it's a change.
                switch newPickerType {
                case .solid where !oldStyle.isSolid:
                    newBackgroundStyle = .solid(CodableColor(color: .gray))
                case .gradient where !oldStyle.isGradient:
                    let baseColor = oldStyle.solidColor ?? (oldStyle.imageModel?.averageColor ?? CodableColor(color: .blue))
                    newBackgroundStyle = .gradient(GradientModel(
                        colors: [baseColor, CodableColor(color: baseColor.color.opacity(0.5))],
                        startPoint: .init(unitPoint: .topLeading), endPoint: .init(unitPoint: .bottomTrailing)
                    ))
                case .image where !oldStyle.isImage:
                    newBackgroundStyle = .image(ImageBackgroundModel()) // Default empty image model
                default:
                    // No change needed if the type is already correct.
                    return
                }

                // If a new style was determined, apply it and commit the change.
                if let newStyle = newBackgroundStyle {
                    activePage.backgroundStyle = newStyle
                    newProject.updatePage(activePage)
                    document.changeProjectModel(to: newProject, actionName: "Change Background Type")
                }

            }
        )
    }

    // MARK: - Text Element Actions

    private func addTextElement() {
        // Create a mutable copy of the project model struct.
        var newProject = document.project
        
        // Safely get the active page from the new model copy.
        guard var activePage = newProject.activePage else { return }
        
        // Apply the change to the page copy.
        let newElement = TextElementConfig(text: "New Text", positionRatio: CGPoint(x: 0.5, y: 0.5))
        activePage.textElements.append(newElement)
        
        // Update the page in the project model copy.
        newProject.updatePage(activePage)
        
        // Call the centralized change function to apply the update and register undo.
        document.changeProjectModel(to: newProject, actionName: "Add Text Element")
        
        // Update local UI state *after* the model has been changed.
        selectedTextElementID = newElement.id
    }

    private func deleteTextElements(at offsets: IndexSet) {
        // Create a mutable copy of the project model to avoid direct mutation.
        var newProject = document.project
        guard var activePage = newProject.activePage else { return }

        // Identify which elements will be deleted to update selection state later.
        let idsToDelete = Set(offsets.map { activePage.textElements[$0].id })

        // Perform the deletion on the page copy.
        activePage.textElements.remove(atOffsets: offsets)
        
        // Update the page within the project copy.
        newProject.updatePage(activePage)

        // Atomically apply the change and register a single undo action.
        document.changeProjectModel(to: newProject, actionName: "Delete Text Element(s)")

        // Update local UI state *after* the model change.
        if let currentSelectedID = selectedTextElementID, idsToDelete.contains(currentSelectedID) {
            selectedTextElementID = nil
        }
    }

    private func moveTextElement(up: Bool) {
        // Create a mutable copy of the project model.
        var newProject = document.project
        guard var activePage = newProject.activePage,
              let selectedID = selectedTextElementID,
              let currentIndex = activePage.textElements.firstIndex(where: { $0.id == selectedID }) else { return }

        // Determine the target index and ensure it's valid.
        let targetIndex = up ? currentIndex - 1 : currentIndex + 1
        guard activePage.textElements.indices.contains(targetIndex) else { return }

        // Perform the swap on the page copy.
        activePage.textElements.swapAt(currentIndex, targetIndex)
        
        // Update the page within the project copy.
        newProject.updatePage(activePage)

        // Atomically apply the change and register a single undo action.
        let actionName = up ? "Move Element Up" : "Move Element Down"
        document.changeProjectModel(to: newProject, actionName: actionName)
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
        var newProject = document.project
        newProject.pages.append(samplePage)
        newProject.activePageID = samplePage.id
        document.changeProjectModel(to: newProject, actionName: "Add New Page")
        
        return InspectorView(document: document)
            .frame(width: 320) // Typical inspector width
            .previewDisplayName("InspectorView with Document")
    }
}