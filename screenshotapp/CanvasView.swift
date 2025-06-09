import SwiftUI
import UniformTypeIdentifiers // For export and import panels

// Assuming DeviceMockupView, TemplateProvider, and View+Render.swift (for .renderAsImage) exist.

// Top-level helper function (Consider moving inside CanvasView or an extension if not used elsewhere)
private func mapFrameAlignmentToTextAlignment(_ frameAlignment: Alignment) -> TextAlignment {
    switch frameAlignment {
    case .leading: return .leading
    case .center: return .center
    case .trailing: return .trailing
    default: return .center // Default or best guess
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
    
    @State private var selectedTemplateID: UUID? = screenshotapp.TemplateProvider.templates.first?.id
    
    @State private var scale: CGFloat = 1.0
    @State private var deviceDragGestureState = CGSize.zero
    @State private var draggingTextElementID: UUID? = nil
    @State private var textDragGestureState: CGSize = .zero
    
    // Store initial drag offsets for text elements to ensure undo restores to pre-gesture state
    @State private var initialDragOffsets: [UUID: (positionRatio: CGPoint, offsetPixels: CGSize)] = [:]

    private var currentImportedNSImage: NSImage? {
        guard let currentPage = document.project.activePage, let data = currentPage.importedImage else { return nil }
        return NSImage(data: data)
    }
    
    private var deviceFrameBinding: Binding<DeviceFrameType> {
        Binding(
            get: { document.project.activePage?.deviceFrameType ?? .iPhone15Pro },
            set: { newDeviceFrameType in
                guard var currentPage = document.project.activePage else { return }
                let oldPage = currentPage
                
                if currentPage.deviceFrameType != newDeviceFrameType {
                    currentPage.deviceFrameType = newDeviceFrameType
                    currentPage.updateCanvasSizeToDefault()
                    document.project.activePage = currentPage
                    
                    let oldPageID = oldPage.id // All properties of oldPage are captured by value here.

                    undoManager?.registerUndo(withTarget: document) { doc_in_undo in
                        Task { @MainActor in
                            if var pageToRestore = doc_in_undo.project.pages.first(where: { $0.id == oldPageID }) {
                                pageToRestore.deviceFrameType = oldPage.deviceFrameType
                                pageToRestore.canvasSize = oldPage.canvasSize
                                pageToRestore.importedImage = oldPage.importedImage
                                doc_in_undo.project.updatePage(pageToRestore)
                            }
                        }
                    }
                    undoManager?.setActionName("Change Device Frame")
                }
            }
        )
    }
    
    private var imageScaleBinding: Binding<CGFloat> {
        Binding<CGFloat>(
            get: { self.document.project.activePage?.imageScale ?? 1.0 },
            set: { newScale in
                guard let pageID = self.document.project.activePage?.id else { return }
                let oldScale = self.document.project.activePage?.imageScale ?? 1.0

                self.undoManager?.registerUndo(withTarget: self.document) { doc in
                    Task { @MainActor in
                        if var pageToRestore = doc.project.pages.first(where: { $0.id == pageID }) {
                            pageToRestore.imageScale = oldScale
                            doc.project.updatePage(pageToRestore)
                        }
                    }
                }
                self.undoManager?.setActionName("Adjust Image Scale")

                Task { @MainActor in
                    if var pageToUpdate = self.document.project.pages.first(where: { $0.id == pageID }) {
                        pageToUpdate.imageScale = newScale
                        self.document.project.updatePage(pageToUpdate)
                    }
                }
            }
        )
    }

    private var imageOffsetXBinding: Binding<CGFloat> {
        Binding<CGFloat>(
            get: { self.document.project.activePage?.imageOffset.cgSize.width ?? 0.0 },
            set: { newOffsetX in
                guard let pageID = self.document.project.activePage?.id else { return }
                let oldOffset = self.document.project.activePage?.imageOffset.cgSize ?? .zero

                self.undoManager?.registerUndo(withTarget: self.document) { doc in
                    Task { @MainActor in
                        if var pageToRestore = doc.project.pages.first(where: { $0.id == pageID }) {
                            pageToRestore.imageOffset = CodableCGSize(size: oldOffset)
                            doc.project.updatePage(pageToRestore)
                        }
                    }
                }
                self.undoManager?.setActionName("Adjust Image Offset X")

                Task { @MainActor in
                    if var pageToUpdate = self.document.project.pages.first(where: { $0.id == pageID }) {
                        var currentOffset = pageToUpdate.imageOffset.cgSize
                        currentOffset.width = newOffsetX
                        pageToUpdate.imageOffset = CodableCGSize(size: currentOffset)
                        self.document.project.updatePage(pageToUpdate)
                    }
                }
            }
        )
    }

    private var imageOffsetYBinding: Binding<CGFloat> {
        Binding<CGFloat>(
            get: { self.document.project.activePage?.imageOffset.cgSize.height ?? 0.0 },
            set: { newOffsetY in
                guard let pageID = self.document.project.activePage?.id else { return }
                let oldOffset = self.document.project.activePage?.imageOffset.cgSize ?? .zero

                self.undoManager?.registerUndo(withTarget: self.document) { doc in
                    Task { @MainActor in
                        if var pageToRestore = doc.project.pages.first(where: { $0.id == pageID }) {
                            pageToRestore.imageOffset = CodableCGSize(size: oldOffset)
                            doc.project.updatePage(pageToRestore)
                        }
                    }
                }
                self.undoManager?.setActionName("Adjust Image Offset Y")

                Task { @MainActor in
                    if var pageToUpdate = self.document.project.pages.first(where: { $0.id == pageID }) {
                        var currentOffset = pageToUpdate.imageOffset.cgSize
                        currentOffset.height = newOffsetY
                        pageToUpdate.imageOffset = CodableCGSize(size: currentOffset)
                        self.document.project.updatePage(pageToUpdate)
                    }
                }
            }
        )
    }

    var body: some View {
        HSplitView {
            // Controls Panel
            VStack(alignment: .leading, spacing: 15) {
                Text("Canvas Controls").font(.title2).padding(.bottom, 5)
                Button(action: importImageWithUndo) {
                    Text(document.project.activePage?.importedImage == nil ? "Import Screenshot" : "Replace Screenshot")
                }
                .disabled(document.project.activePage == nil)
                .padding(.vertical, 5)
                
                if let nsImage = currentImportedNSImage {
                    Image(nsImage: nsImage)
                        .resizable().aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 200, maxHeight: 150).border(Color.gray).padding(.bottom, 5)
                }
                
                Picker("Template", selection: $selectedTemplateID) {
                    let templates: [screenshotapp.AppScreenshotTemplate] = screenshotapp.TemplateProvider.templates
                    ForEach(templates, id: \.id) { template in
                        Text(template.name).tag(template.id as UUID?)
                    }
                }
                .onChange(of: selectedTemplateID) { _ in applySelectedTemplateWithUndo() }
                .padding(.bottom, 5)
                
                Picker("Device", selection: deviceFrameBinding) {
                    ForEach(DeviceFrameType.allCases) { Text($0.displayName).tag($0) }
                }
                .padding(.bottom, 5)

                Section("Imported Image Adjustments") {
                    VStack(alignment: .leading) {
                        Text("Scale: \(document.project.activePage?.imageScale ?? 1.0, specifier: "%.2f")")
                        Slider(value: imageScaleBinding, in: 0.2...5.0, step: 0.05) {
                            Text("Scale") // Accessibility label
                        }
                    }
                    Stepper("Offset X: \(Int(document.project.activePage?.imageOffset.cgSize.width ?? 0)) px", value: imageOffsetXBinding, step: 5)
                    Stepper("Offset Y: \(Int(document.project.activePage?.imageOffset.cgSize.height ?? 0)) px", value: imageOffsetYBinding, step: 5)
                }
                .disabled(document.project.activePage?.importedImage == nil)
                .padding(.bottom, 5)
                
                ColorPicker("Solid Background", selection: Binding(
                    get: {
                        if let page = document.project.activePage, case .solid(let color) = page.backgroundStyle {
                            return color.color
                        }
                        return .gray
                    },
                    set: { newColor in
                        changeBackgroundStyleWithUndo(to: .solid(CodableColor(color: newColor)))
                    }
                ), supportsOpacity: true)
                .disabled(document.project.activePage == nil)
                .padding(.bottom, 5)
                
                Spacer()
                Button(action: exportScreenshot) {
                    Text("Export Screenshot").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent).padding(.vertical, 10)
                .disabled(document.project.activePage?.importedImage == nil)
            }
            .padding().frame(minWidth: 280, idealWidth: 320, maxWidth: 400)
            
            // Preview Panel
            GeometryReader { geometry in
                ZStack {
                    if let activePage = document.project.activePage {
                        // Background Rendering
                        switch activePage.backgroundStyle {
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
                                ZStack { // Tiling logic
                                    switch imageModel.tilingMode {
                                    case .stretch: // Assuming stretch means tile if image is smaller than view
                                        GeometryReader { geoTile in 
                                            if nsImage.size.width > 0 && nsImage.size.height > 0 {
                                                let imageWidth = nsImage.size.width
                                                let imageHeight = nsImage.size.height
                                                let columns = Int(ceil(geoTile.size.width / imageWidth))
                                                let rows = Int(ceil(geoTile.size.height / imageHeight))
                                                VStack(alignment: .leading, spacing: 0) {
                                                    ForEach(0..<max(1, rows), id: \.self) { _ in
                                                        HStack(alignment: .top, spacing: 0) {
                                                            ForEach(0..<max(1, columns), id: \.self) { _ in
                                                                swiftUIImage.resizable().frame(width: imageWidth, height: imageHeight)
                                                            }
                                                        }
                                                    }
                                                }
                                                .frame(width: CGFloat(max(1, columns)) * imageWidth, height: CGFloat(max(1, rows)) * imageHeight, alignment: .topLeading)
                                            } else {
                                                 swiftUIImage.resizable().scaledToFit().frame(maxWidth: .infinity, maxHeight: .infinity)
                                            }
                                        }
                                       .opacity(imageModel.opacity)
                                    case .aspectFit:
                                        swiftUIImage.resizable().scaledToFit().frame(maxWidth: .infinity, maxHeight: .infinity).opacity(imageModel.opacity)
                                    case .aspectFill:
                                        swiftUIImage.resizable().scaledToFill().frame(maxWidth: .infinity, maxHeight: .infinity).opacity(imageModel.opacity)
                                    @unknown default:
                                        swiftUIImage.resizable().scaledToFit().frame(maxWidth: .infinity, maxHeight: .infinity).opacity(imageModel.opacity)
                                    }
                                }
                                .edgesIgnoringSafeArea(.all)
                                .clipped()
                            } else {
                                Rectangle().fill(Color.gray.opacity(0.3)).overlay(Text("Image Not Loaded").foregroundColor(.white)).edgesIgnoringSafeArea(.all)
                            }
                        @unknown default:
                             Rectangle().fill(Color.gray.opacity(0.1)).overlay(Text("Unsupported Background").foregroundColor(.white)).edgesIgnoringSafeArea(.all)
                        }

                        // Device Mockup Rendering
                        DeviceMockupView(
                            image: self.currentImportedNSImage,
                            deviceType: activePage.deviceFrameType.deviceType,
                            backgroundColor: self.backgroundColorForDeviceMockupView(for: activePage.backgroundStyle),
                            targetHeight: nil, // No target height for live preview, it scales to fit geometry
                            imageScale: activePage.imageScale,
                            imageOffset: activePage.imageOffset.cgSize)
                        .offset(self.deviceDragGestureState)
                        .gesture(
                            DragGesture()
                                .onChanged { value in self.deviceDragGestureState = value.translation }
                                .onEnded { value in
                                    let capturedDocument = self.document
                                    let capturedUndoManager = self.undoManager
                                    let pageID = activePage.id // activePage is already captured from outer scope
                                    let oldDeviceFrameOffset = activePage.deviceFrameOffset // Capture before change
                                    let newDeviceFrameOffset = CodableCGSize(size: CGSize(width: oldDeviceFrameOffset.width + value.translation.width, height: oldDeviceFrameOffset.height + value.translation.height))

                                    capturedUndoManager?.registerUndo(withTarget: capturedDocument) { doc_in_undo in
                                        Task { @MainActor in
                                            if var pageToRestore = doc_in_undo.project.pages.first(where: { $0.id == pageID }) {
                                                pageToRestore.deviceFrameOffset = oldDeviceFrameOffset
                                                doc_in_undo.project.updatePage(pageToRestore)
                                            }
                                        }
                                    }
                                    capturedUndoManager?.setActionName("Move Device")

                                    Task { @MainActor in
                                        if var pageToUpdate = capturedDocument.project.pages.first(where: { $0.id == pageID }) {
                                            pageToUpdate.deviceFrameOffset = newDeviceFrameOffset
                                            capturedDocument.project.updatePage(pageToUpdate)
                                        }
                                    }
                                    self.deviceDragGestureState = .zero
                                }
                        )
                        
                        // Text Elements Rendering
                        ForEach(activePage.textElements) { textElement in
                            renderTextElement(element: textElement, canvasProxySize: geometry.size)
                        }
                    } else {
                        ContentUnavailableView("No Active Page", systemImage: "doc.richtext.fill")
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            if selectedTemplateID == nil {
                selectedTemplateID = screenshotapp.TemplateProvider.templates.first?.id
            }
            // applySelectedTemplateWithUndo(isInitialAppearance: true) // Consider if needed on initial appear
        }
        .onChange(of: exportTrigger) { _ in // Changed to _ as newValue is not used
            if exportTrigger != nil {
                exportScreenshot()
                exportTrigger = nil
            }
        }
    } // End of body

    // MARK: - Text Element Rendering
    @ViewBuilder
    private func renderTextElement(element: TextElementConfig, canvasProxySize: CGSize) -> some View {
        let text = Text(LocalizedStringKey(element.text))
            .font(.custom(element.fontName, size: element.fontSize))
            .foregroundColor(element.textColor.color)
            .multilineTextAlignment(element.textAlignment.alignment)
        
        let frameWidth = element.frameWidthRatio != nil ? canvasProxySize.width * element.frameWidthRatio! : nil
        let frameHeight = element.frameHeightRatio != nil ? canvasProxySize.height * element.frameHeightRatio! : nil
        
        text
            .frame(width: frameWidth, height: frameHeight, alignment: element.frameAlignment.alignment)
            .padding(element.padding.edgeInsets)
            .background(element.backgroundColor.color.opacity(element.backgroundOpacity))
            .border(element.borderColor.color, width: element.borderWidth)
            .rotationEffect(.degrees(element.rotationAngle))
            .scaleEffect(element.scale)
            .shadow(color: element.shadowColor.color.opacity(element.shadowOpacity), radius: element.shadowRadius, x: element.shadowOffset.width, y: element.shadowOffset.height)
            .position(
                x: element.positionRatio.x * canvasProxySize.width + element.offsetPixels.width + (draggingTextElementID == element.id ? textDragGestureState.width : 0),
                y: element.positionRatio.y * canvasProxySize.height + element.offsetPixels.height + (draggingTextElementID == element.id ? textDragGestureState.height : 0)
            )
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if self.initialDragOffsets[element.id] == nil {
                            // Store the state at the beginning of this distinct drag gesture
                            self.initialDragOffsets[element.id] = (element.positionRatio, element.offsetPixels)
                        }
                        self.draggingTextElementID = element.id
                        self.textDragGestureState = value.translation
                    }
                    .onEnded { value in
                        let capturedDocument = self.document
                        let capturedUndoManager = self.undoManager
                        
                        guard let pageID = capturedDocument.project.activePage?.id else { 
                            self.draggingTextElementID = nil; self.textDragGestureState = .zero; self.initialDragOffsets[element.id] = nil; return 
                        }
                        let textElementID = element.id

                        // Use initialDragOffsets if set, otherwise use current element's state as pre-drag state
                        let (oldPositionRatio, oldOffsetPixels) = self.initialDragOffsets[textElementID] ?? (element.positionRatio, element.offsetPixels)

                        // Calculate new state based on drag translation relative to the start of the gesture
                        let newPositionRatio = CGPoint(
                            x: oldPositionRatio.x + (value.translation.width / canvasProxySize.width),
                            y: oldPositionRatio.y + (value.translation.height / canvasProxySize.height)
                        )
                        // Assuming offsetPixels are not the primary target of this drag, or handled if they are.
                        // If offsetPixels are meant to be changed by drag, their original state before this drag gesture started is needed.
                        let newOffsetPixels = oldOffsetPixels // Or: element.offsetPixels if it's meant to be an absolute value set elsewhere

                        capturedUndoManager?.registerUndo(withTarget: capturedDocument) { doc_in_undo_closure in
                            Task { @MainActor in
                                if var pageToRestore = doc_in_undo_closure.project.pages.first(where: { $0.id == pageID }),
                                   let idx = pageToRestore.textElements.firstIndex(where: { $0.id == textElementID }) {
                                    pageToRestore.textElements[idx].positionRatio = oldPositionRatio
                                    pageToRestore.textElements[idx].offsetPixels = oldOffsetPixels
                                    doc_in_undo_closure.project.updatePage(pageToRestore)
                                }
                            }
                        }
                        capturedUndoManager?.setActionName("Move Text")

                        Task { @MainActor in
                            if var pageToUpdate = capturedDocument.project.pages.first(where: { $0.id == pageID }),
                               let idx = pageToUpdate.textElements.firstIndex(where: { $0.id == textElementID }) {
                                pageToUpdate.textElements[idx].positionRatio = newPositionRatio
                                pageToUpdate.textElements[idx].offsetPixels = newOffsetPixels
                                capturedDocument.project.updatePage(pageToUpdate)
                            }
                        }
                        self.draggingTextElementID = nil
                        self.textDragGestureState = .zero
                        self.initialDragOffsets[element.id] = nil // Clear for next distinct gesture
                    }
            )
    }

    // MARK: - Undoable Actions
    private func changeBackgroundStyleWithUndo(to newStyle: BackgroundStyle) {
        guard var currentPage = document.project.activePage else { return }
        let oldPage = currentPage
        
        currentPage.backgroundStyle = newStyle
        document.project.activePage = currentPage
        
        let oldPageID = oldPage.id // All properties of oldPage captured by value

        undoManager?.registerUndo(withTarget: document) { doc_in_undo in
            Task { @MainActor in
                if var pageToRestore = doc_in_undo.project.pages.first(where: { $0.id == oldPageID }) {
                    pageToRestore.backgroundStyle = oldPage.backgroundStyle // Restore relevant part
                    // Restore other parts of oldPage if newStyle affects them indirectly
                    doc_in_undo.project.updatePage(pageToRestore)
                }
            }
        }
        undoManager?.setActionName("Change Background Style")
    }

    private func importImageWithUndo() {
        guard document.project.activePage != nil else { return }
        
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .heic, .tiff, .gif, .bmp]
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Import"
        
        if panel.runModal() == .OK, let url = panel.url {
            do {
                let imageData = try Data(contentsOf: url)
                guard NSImage(data: imageData) != nil else { return }
                
                guard var currentPage = document.project.activePage else { return }
                let oldPage = currentPage
                
                currentPage.importedImage = imageData
                currentPage.updateCanvasSizeToDefault()
                document.project.activePage = currentPage
                
                let oldPageID = oldPage.id
                let oldImportedImage = oldPage.importedImage // Capture specific old data
                let oldCanvasSize = oldPage.canvasSize

                undoManager?.registerUndo(withTarget: document) { doc_in_undo in
                    Task { @MainActor in
                        if var pageToRestore = doc_in_undo.project.pages.first(where: { $0.id == oldPageID }) {
                            pageToRestore.importedImage = oldImportedImage
                            pageToRestore.canvasSize = oldCanvasSize
                            doc_in_undo.project.updatePage(pageToRestore)
                        }
                    }
                }
                undoManager?.setActionName("Import Image")
            } catch {
                print("Error loading image data from URL: \(error)")
            }
        }
    }
    
    @MainActor // Ensure this function is on MainActor as it modifies document.project directly
    private func applySelectedTemplateWithUndo() { // Removed isInitialAppearance
        guard var currentPage = document.project.activePage, // Ensure activePage is not nil
              let templateID = selectedTemplateID,
              let template = screenshotapp.TemplateProvider.template(withId: templateID) else {
            // print("No active page or template selected, or templateID is nil.")
            return
        }
        
        let oldPage = currentPage // Capture for undo
        
        currentPage.textElements = template.textElements.map { config -> TextElementConfig in
            var newConfig = config
            newConfig.id = UUID() // Ensure new unique IDs
            return newConfig
        }
        currentPage.backgroundStyle = template.backgroundStyle
        currentPage.deviceFrameType = template.deviceFrame.deviceType
        currentPage.deviceFrameOffset = CodableCGSize(size: CGSize(width: template.deviceFrame.offset.x, height: template.deviceFrame.offset.y))
        
        if let templateCanvasSize = template.canvasSize {
            currentPage.canvasSize = templateCanvasSize
        } else {
            currentPage.updateCanvasSizeToDefault()
        }
        // currentPage.importedImage = template.importedImageData // If template carries image data
        
        document.project.activePage = currentPage // This should trigger UI update if project is @Published
        
        let oldPageID = oldPage.id // All properties of oldPage captured by value

        undoManager?.registerUndo(withTarget: document) { doc_in_undo in
            // The 'oldPage' struct is captured by value here, which is Sendable.
            Task { @MainActor in
                if var pageToRestore = doc_in_undo.project.pages.first(where: { $0.id == oldPageID }) {
                    // Restore all relevant properties from the captured oldPage
                    pageToRestore.textElements = oldPage.textElements
                    pageToRestore.backgroundStyle = oldPage.backgroundStyle
                    pageToRestore.deviceFrameType = oldPage.deviceFrameType
                    pageToRestore.deviceFrameOffset = oldPage.deviceFrameOffset
                    pageToRestore.canvasSize = oldPage.canvasSize
                    pageToRestore.importedImage = oldPage.importedImage
                    doc_in_undo.project.updatePage(pageToRestore)
                }
            }
        }
        undoManager?.setActionName("Apply Template: \(template.name)")
    }
        
    private func exportScreenshot() {
        guard let activePage = document.project.activePage, activePage.importedImage != nil else {
            return
        }

        let finalCanvasSize = CGSize(width: 1290, height: 2796)

        guard finalCanvasSize.width > 0 && finalCanvasSize.height > 0 else { return }

        // Pre-calculate all necessary values
        let defaultDeviceSize: CGSize
        switch activePage.deviceFrameType.deviceType {
        case .iPhone: defaultDeviceSize = CGSize(width: 200, height: 410)
        case .iPad: defaultDeviceSize = CGSize(width: 300, height: 420)
        case .mac: defaultDeviceSize = CGSize(width: 450, height: 280)
        }

        let deviceTargetHeight = finalCanvasSize.height * 0.85
        let aspectRatio = defaultDeviceSize.width / defaultDeviceSize.height
        let scaledDeviceWidth = deviceTargetHeight * aspectRatio

        let deviceOriginX = (finalCanvasSize.width - scaledDeviceWidth) / 2 + activePage.deviceFrameOffset.width
        let deviceOriginY = (finalCanvasSize.height - deviceTargetHeight) / 2 + activePage.deviceFrameOffset.height
        let deviceFrameInCanvas = CGRect(x: deviceOriginX, y: deviceOriginY, width: scaledDeviceWidth, height: deviceTargetHeight)

        let baseFontDeviceHeight: CGFloat = 410.0 // iPhone default height as base for font scaling
        let fontScaleFactor = deviceTargetHeight / baseFontDeviceHeight

        let viewToRender = ZStack {
            AnyView(
                Group {
                    switch activePage.backgroundStyle {
                    case .solid(let codableColor): codableColor.color
                    case .gradient(let gradientModel):
                        LinearGradient(gradient: Gradient(colors: gradientModel.colors.map { $0.color }),
                                       startPoint: gradientModel.startPoint.unitPoint,
                                       endPoint: gradientModel.endPoint.unitPoint)
                    case .image(let imageModel):
                        if let imgData = imageModel.imageData, let bgNsImage = NSImage(data: imgData) {
                            Image(nsImage: bgNsImage).resizable().scaledToFill().opacity(imageModel.opacity)
                        } else { Color.gray }
                    }
                }
            )

            DeviceMockupView(
                image: activePage.importedImage.flatMap { NSImage(data: $0) },
                deviceType: activePage.deviceFrameType.deviceType,
                backgroundColor: self.backgroundColorForDeviceMockupViewExport(activePage: activePage),
                targetHeight: deviceTargetHeight,
                imageScale: activePage.imageScale,
                imageOffset: activePage.imageOffset.cgSize
            )
            .frame(width: scaledDeviceWidth, height: deviceTargetHeight)
            .position(x: deviceFrameInCanvas.midX, y: deviceFrameInCanvas.midY)

            ForEach(activePage.textElements) { textElement in
                renderTextElementForExport(textElement: textElement, deviceFrameInCanvas: deviceFrameInCanvas, fontScaleFactor: fontScaleFactor)
            }
        }
        .frame(width: finalCanvasSize.width, height: finalCanvasSize.height)
        .clipped()

        guard let imageToExport = viewToRender.renderAsImage(size: finalCanvasSize) else { return }

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [UTType.png]
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = activePage.name ?? "Screenshot-\(Int(Date().timeIntervalSince1970)).png"
        savePanel.prompt = "Export"

        if savePanel.runModal() == .OK, let url = savePanel.url {
            do {
                guard let pngData = imageToExport.pngData() else { return }
                try pngData.write(to: url)
            } catch {
                print("Error saving exported image: \(error.localizedDescription)")
            }
        }
    }
    
    private func backgroundColorForDeviceMockupView(for backgroundStyle: BackgroundStyle) -> Color {
        switch backgroundStyle {
        case .solid(let codableColor): return codableColor.color
        case .gradient, .image: return .clear
        }
    }
    
    private func backgroundColorForDeviceMockupViewExport(activePage: ScreenshotPage) -> Color {
        switch activePage.backgroundStyle {
        case .solid(let codableColor): return codableColor.color
        case .gradient, .image: return .clear
        }
    }

    @ViewBuilder
    private func renderTextElementForExport(textElement: TextElementConfig, deviceFrameInCanvas: CGRect, fontScaleFactor: CGFloat) -> some View {
        Text(textElement.text)
            .font(.custom(textElement.fontName, size: textElement.fontSize * fontScaleFactor))
            .foregroundColor(textElement.textColor.color)
            .multilineTextAlignment(textElement.textAlignment.alignment)
            .frame(width: textElement.frameWidthRatio != nil ? deviceFrameInCanvas.width * textElement.frameWidthRatio! : nil,
                   height: textElement.frameHeightRatio != nil ? deviceFrameInCanvas.height * textElement.frameHeightRatio! : nil,
                   alignment: textElement.frameAlignment.alignment)
            .padding(textElement.padding.edgeInsets)
            .background(textElement.backgroundColor.color.opacity(textElement.backgroundOpacity))
            .border(textElement.borderColor.color, width: textElement.borderWidth)
            .rotationEffect(.degrees(textElement.rotationAngle))
            .scaleEffect(textElement.scale)
            .shadow(color: textElement.shadowColor.color.opacity(textElement.shadowOpacity), radius: textElement.shadowRadius, x: textElement.shadowOffset.width, y: textElement.shadowOffset.height)
            .position(x: deviceFrameInCanvas.origin.x + (textElement.positionRatio.x * deviceFrameInCanvas.width) + (textElement.offsetPixels.width * fontScaleFactor),
                       y: deviceFrameInCanvas.origin.y + (textElement.positionRatio.y * deviceFrameInCanvas.height) + (textElement.offsetPixels.height * fontScaleFactor))
    }
} // End of CanvasView struct

struct CanvasView_Previews: PreviewProvider {
    // Removed duplicate mapFrameAlignmentToTextAlignment from previews
    static var previews: some View {
        let dummyDocument = ScreenshotProjectDocument()
        let image = NSImage(systemSymbolName: "photo", accessibilityDescription: nil)

        let sampleTextElement = TextElementConfig(
            id: UUID(), text: "Sample Text", fontName: "Helvetica", fontSize: 30,
            textColor: CodableColor(color: .white), textAlignment: CodableTextAlignment(.center),
            frameAlignment: CodableAlignment(.center), positionRatio: CGPoint(x: 0.5, y: 0.2),
            offsetPixels: CGSize.zero, frameWidthRatio: 0.8, frameHeightRatio: nil,
            padding: CodableEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10),
            backgroundColor: CodableColor(color: .blue), backgroundOpacity: 0.5,
            borderColor: CodableColor(color: .black), borderWidth: 2, rotationAngle: 0, scale: 1.0,
            shadowColor: CodableColor(color: .black), shadowOpacity: 0.3, shadowRadius: 5,
            shadowOffset: CGSize(width: 2, height: 2)
        )

        var samplePage = ScreenshotPage(id: UUID(), name: "Sample Page 1", importedImage: image?.pngData(), deviceFrameType: .iPhone15Pro)
        samplePage.backgroundStyle = BackgroundStyle.solid(CodableColor(color: Color(NSColor.lightGray)))
        samplePage.textElements = [sampleTextElement]

        dummyDocument.project.pages = [samplePage]
        dummyDocument.project.activePageID = samplePage.id

        return CanvasView(document: dummyDocument, exportTrigger: .constant(nil))
    }
} // End of CanvasView_Previews struct
