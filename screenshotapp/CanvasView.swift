import SwiftUI
import UniformTypeIdentifiers // For export and import panels

// Assuming DeviceMockupView, TemplateProvider, and View+Render.swift (for .renderAsImage) exist.

// Top-level helper function
private func mapFrameAlignmentToTextAlignment(_ frameAlignment: Alignment) -> TextAlignment {
    switch frameAlignment {
    case .leading:
        return .leading
    case .center:
        return .center
    case .trailing:
        return .trailing
    default: // .top, .bottom, .topLeading, .topTrailing, .bottomLeading, .bottomTrailing etc.
        return .center // Default or best guess for other frame alignments
    }
}

extension NSImage {
    func pngData() -> Data? {
        guard let tiffRepresentation = self.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else {
            return nil
        }
        return bitmapImage.representation(using: .png, properties: [:])
    }
}

struct CanvasView: View {
    @ObservedObject var document: ScreenshotProjectDocument
    @Environment(\.undoManager) var undoManager
    @Binding var exportTrigger: UUID?

    @State private var selectedTemplateID: UUID? = TemplateProvider.templates.first?.id
    
    // For pan and zoom (placeholders)
    @State private var scale: CGFloat = 1.0 // For pan/zoom (placeholder)
    // @State private var offset: CGSize = .zero // This might be consolidated or used by pan/zoom

    // For live dragging of the device mockup
    @State private var deviceDragGestureState = CGSize.zero

    // For live dragging of text elements
    @State private var draggingTextElementID: UUID? = nil
    @State private var textDragGestureState: CGSize = .zero

    // Computed property for the imported NSImage
    private var currentImportedNSImage: NSImage? {
        guard let data = document.project.importedImage else { return nil }
        return NSImage(data: data)
    }
    
    // Binding for device frame picker
    private var deviceFrameBinding: Binding<DeviceFrameType> {
        Binding(
            get: { document.project.deviceFrame },
            set: { newDeviceFrame in
                let oldDeviceFrame = document.project.deviceFrame
                if oldDeviceFrame != newDeviceFrame {
                    DispatchQueue.main.async {
                        document.project.deviceFrame = newDeviceFrame
                    }
                    undoManager?.registerUndo(withTarget: document, handler: { doc in
                        DispatchQueue.main.async {
                            doc.project.deviceFrame = oldDeviceFrame
                        }
                    })
                    undoManager?.setActionName("Change Device Frame")
                }
            }
        )
    }

    private func mapTextAlignmentToFrameAlignment(_ textAlignment: SwiftUI.TextAlignment) -> SwiftUI.Alignment {
        switch textAlignment {
        case .leading:
            return .leading
        case .center:
            return .center
        case .trailing:
            return .trailing
        @unknown default:
            return .center
        }
    }

    var body: some View {
        HSplitView {
            // Controls Panel
            VStack(alignment: .leading, spacing: 15) {
                Text("Canvas Controls").font(.title2).padding(.bottom, 5)

                Button(action: importImageWithUndo) {
                    Text(document.project.importedImage == nil ? "Import Screenshot" : "Replace Screenshot")
                }
                .padding(.vertical, 5)

                if let nsImage = currentImportedNSImage {
                    Image(nsImage: nsImage)
                        .resizable().aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 200, maxHeight: 150).border(Color.gray).padding(.bottom, 5)
                }

                Picker("Template", selection: $selectedTemplateID) {
                    ForEach(TemplateProvider.templates) { Text($0.name).tag($0.id as UUID?) }
                }
                .onChange(of: selectedTemplateID) { _ in applySelectedTemplateWithUndo() }
                .padding(.bottom, 5)

                Picker("Device", selection: deviceFrameBinding) {
                    ForEach(DeviceFrameType.allCases) { Text($0.displayName).tag($0) }
                }
                .pickerStyle(SegmentedPickerStyle()).padding(.bottom, 5)
                
                ColorPicker("Solid Background", selection: Binding(
                    get: {
                        if case .solid(let color) = document.project.backgroundStyle {
                            return color.color
                        }
                        return .gray // Default if not solid
                    },
                    set: { newColor in
                        changeBackgroundStyleWithUndo(to: .solid(CodableColor(color: newColor)))
                    }
                ), supportsOpacity: true)
                .padding(.bottom, 5)
                // TODO: Add controls for gradient backgrounds later
                
                Spacer()
                
                Button(action: exportScreenshot) {
                    Text("Export Screenshot").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent).padding(.vertical, 10)
                .disabled(document.project.importedImage == nil)
            }
            .padding().frame(minWidth: 280, idealWidth: 320, maxWidth: 400)

            // Preview Panel
            GeometryReader { geometry in
                ZStack {
                    // Render background
                    switch document.project.backgroundStyle {
                    case .solid(let codableColor):
                        codableColor.color.edgesIgnoringSafeArea(.all)
                    case .gradient(let gradientModel):
                        LinearGradient(
                            gradient: Gradient(colors: gradientModel.colors.map { $0.color }),
                            startPoint: gradientModel.startPoint.unitPoint,
                            endPoint: gradientModel.endPoint.unitPoint
                        ).edgesIgnoringSafeArea(.all)
                    case .image(let imageModel):
                        if let imageData = imageModel.imageData, let nsImage = NSImage(data: imageData) {
                            let swiftUIImage = Image(nsImage: nsImage)
                            
                            ZStack {
                                    switch imageModel.tilingMode {
                                    case .stretch: // Stretch to fill, may not preserve aspect ratio perfectly with simple modifiers
                                        swiftUIImage
                                    GeometryReader { geo in
                                        if nsImage.size.width > 0 && nsImage.size.height > 0 {
                                            let imageWidth = nsImage.size.width
                                            let imageHeight = nsImage.size.height
                                            
                                            let columns = Int(ceil(geo.size.width / imageWidth))
                                            let rows = Int(ceil(geo.size.height / imageHeight))
                                            
                                            VStack(alignment: .leading, spacing: 0) {
                                                ForEach(0..<rows, id: \.self) { _ in
                                                    HStack(alignment: .top, spacing: 0) {
                                                        ForEach(0..<columns, id: \.self) { _ in
                                                            swiftUIImage
                                                                .resizable() // Allow it to be framed
                                                                .frame(width: imageWidth, height: imageHeight)
                                                        }
                                                    }
                                                }
                                            }
                                            .frame(width: CGFloat(columns) * imageWidth, height: CGFloat(rows) * imageHeight, alignment: .topLeading)
                                            // The .clipped() on the parent ZStack should handle overflow
                                        } else {
                                            // Fallback for zero-size image, treat as aspectFit
                                            swiftUIImage
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        }
                                    }
                                    .opacity(imageModel.opacity)
                                case .aspectFit:
                                    swiftUIImage
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .opacity(imageModel.opacity)
                                case .aspectFill:
                                    swiftUIImage
                                        .resizable()
                                        .scaledToFill()
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .opacity(imageModel.opacity)
                                @unknown default:
                                    swiftUIImage
                                        .resizable()
                                        .scaledToFit() // Fallback to aspectFit
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .opacity(imageModel.opacity)
                                }
                            }
                            // .opacity(imageModel.opacity) // Removed: Opacity is handled within each case
                            .edgesIgnoringSafeArea(.all)
                            .clipped() // Ensure content respects bounds, esp. for .aspectFill
                        } else {
                            // Placeholder if image data is missing
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .overlay(Text("Image Not Loaded").foregroundColor(.white))
                                .edgesIgnoringSafeArea(.all)
                        }
                    @unknown default:
                        Rectangle().fill(Color.gray.opacity(0.1)).overlay(Text("Unsupported Background").foregroundColor(.white)).edgesIgnoringSafeArea(.all)
                    }

                    // Device Mockup (simplified)
                    DeviceMockupView(
                        image: currentImportedNSImage,
                        deviceType: document.project.deviceFrame.deviceType,
                        backgroundColor: {
                            if case let .solid(codableColor) = document.project.backgroundStyle {
                                return codableColor.color
                            } else {
                                return Color.white
                            }
                        }(),
                        textOverlay: document.project.textElements.first?.text ?? "",
                        textColor: document.project.textElements.first?.textColor.color ?? .black,
                        textAlignment: mapTextAlignmentToFrameAlignment(document.project.textElements.first?.textAlignment.alignment ?? .center),
                        fontName: document.project.textElements.first?.fontName ?? "System Font",
                        fontSize: document.project.textElements.first?.fontSize ?? 18
                    )
                    .offset(x: document.project.deviceFrameOffset.cgSize.width + deviceDragGestureState.width,
                            y: document.project.deviceFrameOffset.cgSize.height + deviceDragGestureState.height)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                self.deviceDragGestureState = value.translation
                            }
                            .onEnded { value in
                                let oldOffset = document.project.deviceFrameOffset
                                let newProposedOffset = CGSize(
                                    width: document.project.deviceFrameOffset.cgSize.width + value.translation.width,
                                    height: document.project.deviceFrameOffset.cgSize.height + value.translation.height
                                )
                                
                                DispatchQueue.main.async {
                                    document.project.deviceFrameOffset = CodableCGSize(size: newProposedOffset)
                                    self.deviceDragGestureState = .zero // Reset live drag state
                                    
                                    undoManager?.registerUndo(withTarget: document, handler: { doc in
                                        DispatchQueue.main.async {
                                            doc.project.deviceFrameOffset = oldOffset
                                        }
                                    })
                                    undoManager?.setActionName("Move Device Frame")
                                }
                            }
                    )
                    .scaleEffect(scale) // Keep scale for now, separate from drag offset
                    // TODO: Add pan/zoom gestures here

                    // Render Text Elements
                    ForEach(document.project.textElements) { textElement in
                        renderTextElement(textElement, canvasSize: geometry.size)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            if selectedTemplateID == nil {
                selectedTemplateID = TemplateProvider.templates.first?.id
            }
            applySelectedTemplateWithUndo(isInitialAppearance: true)
        }
        .onChange(of: exportTrigger) {
            if exportTrigger != nil { // newValue is implicitly available if needed, but direct check is fine
                exportScreenshot()
                exportTrigger = nil // Reset the trigger
            }
        }
    }
    
    // MARK: - Text Element Rendering
    @ViewBuilder
    private func renderTextElement(_ element: TextElementConfig, canvasSize: CGSize) -> some View {
        let text = Text(LocalizedStringKey(element.text)) // Use LocalizedStringKey for potential localization
            .font(.custom(element.fontName, size: element.fontSize))
            .foregroundColor(element.textColor.color)
            .multilineTextAlignment(element.textAlignment.alignment)
        
        let frameWidth = element.frameWidthRatio != nil ? canvasSize.width * element.frameWidthRatio! : nil
        let frameHeight = element.frameHeightRatio != nil ? canvasSize.height * element.frameHeightRatio! : nil

        text
            .frame(width: frameWidth, height: frameHeight, alignment: element.frameAlignment.alignment)
            .padding(element.padding.edgeInsets)
            .background(element.backgroundColor.color.opacity(element.backgroundOpacity))
            .border(element.borderColor.color, width: element.borderWidth)
            .rotationEffect(.degrees(element.rotationAngle))
            .scaleEffect(element.scale)
            .shadow(color: element.shadowColor.color.opacity(element.shadowOpacity), radius: element.shadowRadius, x: element.shadowOffset.width, y: element.shadowOffset.height)
            .position(
                x: element.positionRatio.x * canvasSize.width + element.offsetPixels.width + (draggingTextElementID == element.id ? textDragGestureState.width : 0),
                y: element.positionRatio.y * canvasSize.height + element.offsetPixels.height + (draggingTextElementID == element.id ? textDragGestureState.height : 0)
            )
            .gesture(
                DragGesture()
                    .onChanged { value in
                        self.draggingTextElementID = element.id
                        self.textDragGestureState = value.translation
                    }
                    .onEnded { value in
                        guard let index = document.project.textElements.firstIndex(where: { $0.id == element.id }) else {
                            self.draggingTextElementID = nil
                            self.textDragGestureState = .zero
                            return
                        }
                        
                        let oldElement = document.project.textElements[index]
                        var newElement = oldElement
                        
                        newElement.offsetPixels.width += value.translation.width
                        newElement.offsetPixels.height += value.translation.height
                        
                        DispatchQueue.main.async {
                            document.project.textElements[index] = newElement
                        }
                        
                        self.draggingTextElementID = nil
                        self.textDragGestureState = .zero
                        
                        undoManager?.registerUndo(withTarget: document, handler: { doc in
                            DispatchQueue.main.async {
                                if let revertedIndex = doc.project.textElements.firstIndex(where: { $0.id == oldElement.id }) {
                                    doc.project.textElements[revertedIndex] = oldElement
                                }
                            }
                        })
                        undoManager?.setActionName("Move Text")
                    }
            )
    }

    // MARK: - Undoable Actions
    private func changeBackgroundStyleWithUndo(to newStyle: BackgroundStyle) {
        let oldStyle = document.project.backgroundStyle
        // Basic check; for complex enums, might need to be more thorough or rely on Hashable
        // For now, assume if they are different enough for UI change, they are different.
        // A proper Equatable conformance on BackgroundStyle would be better.
        // guard oldStyle != newStyle else { return } // Requires BackgroundStyle to be Equatable

        DispatchQueue.main.async {
            document.project.backgroundStyle = newStyle
        }
        undoManager?.registerUndo(withTarget: document, handler: { doc in
            DispatchQueue.main.async {
                doc.project.backgroundStyle = oldStyle
            }
        })
        undoManager?.setActionName("Change Background Style")
    }
    
    private func importImageWithUndo() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .heic, .tiff, .gif, .bmp]
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK {
            if let url = panel.url, let data = try? Data(contentsOf: url) {
                let oldImageData = document.project.importedImage
                DispatchQueue.main.async {
                    document.project.importedImage = data
                }
                undoManager?.registerUndo(withTarget: document, handler: { doc in
                    DispatchQueue.main.async {
                        doc.project.importedImage = oldImageData
                    }
                })
                undoManager?.setActionName("Import Screenshot")
            }
        }
    }

    @MainActor
    private func applySelectedTemplateWithUndo(isInitialAppearance: Bool = false) {
        guard let templateID = selectedTemplateID,
              let template = TemplateProvider.templates.first(where: { $0.id == templateID }) else {
            return
        }

        let oldBackgroundStyle = document.project.backgroundStyle
        let oldTextElements = document.project.textElements
        let oldDeviceFrame = document.project.deviceFrame
        // let oldImportedImage = document.project.importedImage // If template could change image

        let newDeviceFrame = DeviceFrameType(deviceType: template.deviceType)

        // Only apply and register undo if something actually changes, or if it's a user action.
        let changed = !isInitialAppearance || oldDeviceFrame != newDeviceFrame

        if changed {
            // Convert backgroundColor to BackgroundStyle.solid
            document.project.backgroundStyle = .solid(CodableColor(color: template.backgroundColor))
            // Convert template's textOverlay and other properties to a TextElementConfig array
            document.project.textElements = [
                TextElementConfig(
                    id: UUID(),
                    text: template.textOverlay,
                    fontName: template.fontName,
                    fontSize: template.fontSize,
                    textColor: CodableColor(color: template.textColor),
                    textAlignment: CodableTextAlignment(mapFrameAlignmentToTextAlignment(template.textAlignment)),
                    frameAlignment: CodableAlignment(template.textAlignment), // Assuming frameAlignment should use textAlignment from template
                    padding: CodableEdgeInsets(),
                    backgroundColor: CodableColor(color: .clear),
                    backgroundOpacity: 0.0,
                    borderColor: CodableColor(color: .clear),
                    borderWidth: 0.0,
                    rotationAngle: 0.0,
                    scale: 1.0,
                    shadowColor: CodableColor(color: .clear),
                    shadowOpacity: 0.0,
                    shadowRadius: 0.0,
                    shadowOffset: CGSize.zero
                )
            ]
            DispatchQueue.main.async {
                document.project.deviceFrame = newDeviceFrame
            }
            
            undoManager?.registerUndo(withTarget: document, handler: { doc in
                DispatchQueue.main.async {
                    doc.project.backgroundStyle = oldBackgroundStyle
                    doc.project.textElements = oldTextElements
                    doc.project.deviceFrame = oldDeviceFrame
                }
            })
            let actionName = isInitialAppearance ? "Apply Initial Template" : "Apply Template: \(template.name)"
            undoManager?.setActionName(actionName)
        }
    }

    // MARK: - Export
    private func exportScreenshot() {
        guard document.project.importedImage != nil else {
            print("No image to export.")
            return
        }

        // Create a view that represents the final exportable content.
        // This needs to be a GeometryReader to get the canvasSize for text positioning.
        // The frame for rendering should match the document's canvasSize.
        let finalCanvasSize = document.project.canvasSize

        let exportView: some View = ZStack {
            // Render background
            switch document.project.backgroundStyle {
            case .solid(let codableColor):
                codableColor.color
            case .gradient(let gradientModel):
                LinearGradient(
                    gradient: Gradient(colors: gradientModel.colors.map { $0.color }),
                    startPoint: gradientModel.startPoint.unitPoint,
                    endPoint: gradientModel.endPoint.unitPoint
                )
            case .image(let imageModel):
                if let imageData = imageModel.imageData, let nsImage = NSImage(data: imageData) {
                    let swiftUIImage = Image(nsImage: nsImage)
                    ZStack { // This ZStack is for the tiling modes
                        switch imageModel.tilingMode {
                        case .stretch:
                            swiftUIImage
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .opacity(imageModel.opacity)
                        case .tile:
                            GeometryReader { geo in
                                if nsImage.size.width > 0 && nsImage.size.height > 0 {
                                    let imageWidth = nsImage.size.width
                                    let imageHeight = nsImage.size.height
                                    let columns = Int(ceil(geo.size.width / imageWidth))
                                    let rows = Int(ceil(geo.size.height / imageHeight))
                                    
                                    VStack(alignment: .leading, spacing: 0) {
                                        ForEach(0..<rows, id: \.self) { _ in
                                            HStack(alignment: .top, spacing: 0) {
                                                ForEach(0..<columns, id: \.self) { _ in
                                                    swiftUIImage
                                                        .resizable()
                                                        .frame(width: imageWidth, height: imageHeight)
                                                }
                                            }
                                        }
                                    }
                                    .frame(width: CGFloat(columns) * imageWidth, height: CGFloat(rows) * imageHeight, alignment: .topLeading)
                                } else {
                                    // Fallback for zero-size image
                                    swiftUIImage
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                }
                            }
                            .opacity(imageModel.opacity)
                        case .aspectFit:
                            swiftUIImage
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .opacity(imageModel.opacity)
                        case .aspectFill:
                            swiftUIImage
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .opacity(imageModel.opacity)
                        @unknown default:
                            swiftUIImage
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .opacity(imageModel.opacity)
                        }
                    }
                    .edgesIgnoringSafeArea(.all)
                    .clipped()
                } else { // Placeholder for missing image
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(Text("Image Not Loaded").foregroundColor(.white))
                        .edgesIgnoringSafeArea(.all)
                }
            @unknown default: // for backgroundStyle
                Rectangle().fill(Color.gray.opacity(0.1)).overlay(Text("Unsupported Background for Export").foregroundColor(.white)).edgesIgnoringSafeArea(.all)
            } // Closes backgroundStyle switch

            // Device Mockup View - Renders the device frame and the main imported image if available.
            // Text overlays are handled separately by the ForEach loop below.
            DeviceMockupView(
                image: document.project.importedImage.flatMap { NSImage(data: $0) }, // Use the main imported image for the mockup
                deviceType: document.project.deviceFrame.deviceType,
                backgroundColor: { // Background for the device mockup area, if needed (e.g., for padding)
                    if case let .solid(codableColor) = document.project.backgroundStyle {
                        return codableColor.color
                    } else {
                        return Color.clear // Transparent, as the main ZStack handles the actual canvas background
                    }
                }(),
                // Text parameters are set to empty/default as text is rendered by the ForEach loop below
                textOverlay: "",
                textColor: .clear,
                textAlignment: .center, // Default, not used if textOverlay is empty
                fontName: "System Font", // Default
                fontSize: 18 // Default
            )

            // Render Text Elements over everything else
            ForEach(document.project.textElements) { textElement in
                renderTextElement(textElement, canvasSize: finalCanvasSize)
            }
        }
        .frame(width: finalCanvasSize.width, height: finalCanvasSize.height)
        .clipped()
        
        guard let imageToExport = exportView.renderAsImage(size: finalCanvasSize) else {
            print("Failed to render image for export.")
            return
        }

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png, .jpeg]
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = "Screenshot-\(document.project.deviceFrame.displayName).png"

        if savePanel.runModal() == .OK {
            if let url = savePanel.url {
                guard let pngData = imageToExport.pngData() else {
                    print("Error: Could not get PNG data.")
                    return
                }

                do {
                    try pngData.write(to: url)
                    print("Image saved to \(url.path)")
                } catch {
                    print("Error saving image: \(error.localizedDescription)")
                }
            }
        }
    }
}

struct CanvasView_Previews: PreviewProvider {
    static var previews: some View {
        let previewDocument = ScreenshotProjectDocument()
        if let firstTemplate = TemplateProvider.templates.first {
            previewDocument.project.backgroundStyle = .solid(CodableColor(color: firstTemplate.backgroundColor))
            previewDocument.project.textElements = [
                TextElementConfig(
                    id: UUID(),
                    text: firstTemplate.textOverlay,
                    fontName: firstTemplate.fontName,
                    fontSize: firstTemplate.fontSize,
                    textColor: CodableColor(color: firstTemplate.textColor),
                    textAlignment: CodableTextAlignment(mapFrameAlignmentToTextAlignment(firstTemplate.textAlignment)),
                    frameAlignment: CodableAlignment(firstTemplate.textAlignment), // Assuming frameAlignment should use textAlignment from template
                    padding: CodableEdgeInsets(),
                    backgroundColor: CodableColor(color: .clear),
                    backgroundOpacity: 0.0,
                    borderColor: CodableColor(color: .clear),
                    borderWidth: 0.0,
                    rotationAngle: 0.0,
                    scale: 1.0,
                    shadowColor: CodableColor(color: .clear),
                    shadowOpacity: 0.0,
                    shadowRadius: 0.0,
                    shadowOffset: CGSize.zero
                    // cornerRadius: 0.0 // Removed: Not a valid parameter
                )
            ]
            previewDocument.project.deviceFrame = DeviceFrameType(deviceType: firstTemplate.deviceType)
        } else {
            // Fallback if no templates are available, provide a default project setup
            previewDocument.project.backgroundStyle = .solid(CodableColor(color: Color(NSColor.lightGray)))
            previewDocument.project.textElements = [
                TextElementConfig(
                    id: UUID(),
                    text: "Preview Text",
                    fontName: "System Font",
                    fontSize: 30,
                    textColor: CodableColor(color: .black),
                    textAlignment: CodableTextAlignment(.center),
                    frameAlignment: CodableAlignment(.center),
                    padding: CodableEdgeInsets(),
                    backgroundColor: CodableColor(color: .clear),
                    backgroundOpacity: 0.0,
                    borderColor: CodableColor(color: .clear),
                    borderWidth: 0.0,
                    rotationAngle: 0.0,
                    scale: 1.0,
                    shadowColor: CodableColor(color: .clear),
                    shadowOpacity: 0.0,
                    shadowRadius: 0.0,
                    shadowOffset: CGSize.zero
                    // cornerRadius: 0.0 // Removed: Not a valid parameter
                )
            ]
            // You might want to set a default device frame and imported image for the preview too
            // previewDocument.project.deviceFrame = .iPhone15Pro // Example
            // if let sampleImage = NSImage(named: "YourSampleImageName") { previewDocument.project.importedImage = sampleImage.tiffRepresentation }
        }
        return CanvasView(document: previewDocument, exportTrigger: .constant(nil))
    }
}