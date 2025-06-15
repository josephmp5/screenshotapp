import SwiftUI
import UniformTypeIdentifiers // For UTType

struct CanvasView: View {
    @Binding var document: ProjectModel
    @Environment(\.undoManager) private var undoManager
    @Binding var selectedTemplateID: String? // For applying templates

    // Internal state reflecting the current page from the document
    @State private var activePage: ScreenshotPage?

    // State for drag gestures on text elements
    @State private var draggedTextElementID: UUID? = nil
    @State private var dragOffset: CGSize = .zero
    @State private var initialDragPosition: CGPoint? = nil
    
    // State for view geometry
    @State private var viewSize: CGSize = .zero

    // Computed properties for easier access
    @MainActor private var currentDeviceFrameType: DeviceFrameType? {
        activePage?.deviceFrameType
    }

    @MainActor private var deviceFrameImage: NSImage? {
        guard let frameName = activePage?.deviceFrameType.deviceType.frameAssetName, !frameName.isEmpty else { return nil }
        return NSImage(named: frameName)
    }

    @MainActor private var screenAreaPixels: CGRect {
        activePage?.deviceFrameType.deviceType.screenAreaPixels ?? .zero
    }

    @MainActor private var screenCornerRadius: CGFloat {
        activePage?.deviceFrameType.deviceType.screenCornerRadius ?? 0
    }

    @MainActor private var userScreenshot: NSImage? {
        guard let imageData = activePage?.importedImage else { return nil }
        return NSImage(data: imageData)
    }

    // MARK: - Computed Views for Body

    @ViewBuilder
    private func canvasBackgroundView(geometry: GeometryProxy) -> some View {
        if let page = activePage {
            switch page.backgroundStyle {
            case .solid(let codableColor):
                codableColor.color
                    .edgesIgnoringSafeArea(.all)
            case .gradient(let gradientModel):
                LinearGradient(gradient: Gradient(colors: gradientModel.colors.map { $0.color }), startPoint: gradientModel.startPoint.unitPoint, endPoint: gradientModel.endPoint.unitPoint)
                    .edgesIgnoringSafeArea(.all)
            case .image(let imageFill):
                if let imageData = imageFill.imageData, let bgImage = NSImage(data: imageData) {
                    Image(nsImage: bgImage)
                        .resizable()
                        .aspectRatio(contentMode: imageFill.tilingMode == .aspectFit ? .fit : .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .edgesIgnoringSafeArea(.all)
                } else {
                    Color.gray // Placeholder if image data is bad
                        .edgesIgnoringSafeArea(.all)
                }
            }
        } else {
            Color.gray // Default background if no active page
                .edgesIgnoringSafeArea(.all)
        }
    }

    @ViewBuilder
    private func deviceAndScreenshotView(geometry: GeometryProxy) -> some View {
        if let page = activePage, let frameImage = deviceFrameImage, screenAreaPixels != .zero {
            DeviceMockupView(
                userScreenshot: userScreenshot,
                deviceFrameImage: frameImage,
                screenAreaPixels: screenAreaPixels,
                screenCornerRadius: screenCornerRadius
            )
            .frame(width: geometry.size.width, height: geometry.size.height)
        } else if activePage?.importedImage != nil, let screenshot = userScreenshot { // Show screenshot if no frame but image exists
            Image(nsImage: screenshot)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: geometry.size.width, height: geometry.size.height)
        } else if activePage != nil { // If page exists but frame is missing
            Text("Device frame asset missing or not selected.")
                .foregroundColor(.red)
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                canvasBackgroundView(geometry: geometry)

                deviceAndScreenshotView(geometry: geometry)

                // Layer 1: Background
                if let page = activePage {
                    switch page.backgroundStyle {
                    case .solid(let codableColor):
                        codableColor.color
                            .edgesIgnoringSafeArea(.all)
                    case .gradient(let gradientModel):
                        LinearGradient(gradient: Gradient(colors: gradientModel.colors.map { $0.color }), startPoint: gradientModel.startPoint.unitPoint, endPoint: gradientModel.endPoint.unitPoint)
                            .edgesIgnoringSafeArea(.all)
                    case .image(let imageFill):
                        if let imageData = imageFill.imageData, let bgImage = NSImage(data: imageData) {
                            Image(nsImage: bgImage)
                                .resizable()
                                .aspectRatio(contentMode: imageFill.tilingMode == .aspectFit ? .fit : .fill)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .clipped()
                                .edgesIgnoringSafeArea(.all)
                        } else {
                            Color.gray // Placeholder if image data is bad
                                .edgesIgnoringSafeArea(.all)
                        }
                    }
                } else {
                    Color.gray // Default background if no active page
                        .edgesIgnoringSafeArea(.all)
                }

                // Layer 2: Device Mockup and Screenshot
                if let page = activePage, let frameImage = deviceFrameImage, screenAreaPixels != .zero {
                    DeviceMockupView(
                        userScreenshot: userScreenshot,
                        deviceFrameImage: frameImage,
                        screenAreaPixels: screenAreaPixels,
                        screenCornerRadius: screenCornerRadius
                    )
                    .frame(width: geometry.size.width, height: geometry.size.height)
                } else if activePage?.importedImage != nil, let screenshot = userScreenshot { // Show screenshot if no frame but image exists
                    Image(nsImage: screenshot)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                } else if activePage != nil { // If page exists but frame is missing
                    Text("Device frame asset missing or not selected.")
                        .foregroundColor(.red)
                }

                // Layer 3: Text Elements
                if let page = activePage {
                    ForEach(page.textElements) { textElement in
                        TextElementView(
                            config: textElementBinding(for: textElement.id),
                            canvasSize: geometry.size,
                            isSelected: .constant(false) // Placeholder - selection state might be managed elsewhere
                        )
                        .position(
                            x: textElement.positionRatio.x * geometry.size.width + (textElement.id == draggedTextElementID ? dragOffset.width : 0),
                            y: textElement.positionRatio.y * geometry.size.height + (textElement.id == draggedTextElementID ? dragOffset.height : 0)
                        )
                        .gesture(
                            DragGesture(minimumDistance: 1, coordinateSpace: .local)
                                .onChanged { value in
                                    handleDragChanged(value: value, textElementID: textElement.id, canvasSize: geometry.size)
                                }
                                .onEnded { value in
                                    handleDragEnded(value: value, textElementID: textElement.id, canvasSize: geometry.size)
                                }
                        )
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
            .onAppear {
                self.viewSize = geometry.size
                self.activePage = document.activePage
            }
            .onChange(of: geometry.size) { newSize in
                self.viewSize = newSize
            }
            .onChange(of: document.activePage) { newActivePage in
                self.activePage = newActivePage // Update local state when document's active page changes
            }
            .onChange(of: selectedTemplateID) { newTemplateID in
                if newTemplateID != nil { // Apply template if a new one is selected
                    applySelectedTemplateWithUndo()
                }
            }
        }
    }

    private func textElementBinding(for elementID: UUID) -> Binding<TextElementConfig> {
        Binding<TextElementConfig>(
            get: {
                if let page = self.activePage, let index = page.textElements.firstIndex(where: { $0.id == elementID }) {
                    return page.textElements[index]
                }
                // This fatalError is a safeguard. In a production app, you might return a default or handle this more gracefully.
                fatalError("TextElement not found for ID: \(elementID) in active page.")
            },
            set: { newConfig in
                Task { @MainActor in
                    var newProject = self.document
                    guard var page = newProject.activePage,
                          let index = page.textElements.firstIndex(where: { $0.id == elementID }) else {
                        print("Attempted to set TextElementConfig for ID \(elementID) but active page or element was not found.")
                        return
                    }
                    page.textElements[index] = newConfig
                    newProject.updatePage(page) // Assumes updatePage correctly finds and updates the page in newProject.pages
                    self.document = newProject
                }
            }
        )
    }

    private func handleDragChanged(value: DragGesture.Value, textElementID: UUID, canvasSize: CGSize) {
        if self.draggedTextElementID == nil { // First change event for this drag
            self.draggedTextElementID = textElementID
            // Store the initial position of the element being dragged, converted to view coordinates
            if let page = self.activePage, let currentElement = page.textElements.first(where: { $0.id == textElementID }) {
                self.initialDragPosition = CGPoint(x: currentElement.positionRatio.x * canvasSize.width, 
                                                   y: currentElement.positionRatio.y * canvasSize.height)
            } else {
                 // Fallback if element not found, though this shouldn't happen if ID is valid
                 self.initialDragPosition = value.startLocation
            }
        }
        // Calculate offset from the initial position
        if let initialPos = self.initialDragPosition {
             self.dragOffset = CGSize(width: value.location.x - initialPos.x, height: value.location.y - initialPos.y)
        }
    }

    private func handleDragEnded(value: DragGesture.Value, textElementID: UUID, canvasSize: CGSize) {
        guard let initialPos = self.initialDragPosition, // Ensure we have an initial position
              var page = self.document.activePage, // Get the active page from the document
              let index = page.textElements.firstIndex(where: { $0.id == textElementID }) else {
            // Reset drag state if any guard fails
            self.draggedTextElementID = nil
            self.dragOffset = .zero
            self.initialDragPosition = nil
            return
        }

        let translation = value.translation
        let finalX = initialPos.x + translation.width // Use width for x translation
        let finalY = initialPos.y + translation.height // Use height for y translation

        // Convert to relative position within canvas bounds
        page.textElements[index].positionRatio.x = max(0, min(1, finalX / canvasSize.width)) // Clamp to 0-1
        page.textElements[index].positionRatio.y = max(0, min(1, finalY / canvasSize.height)) // Clamp to 0-1
        
        Task { @MainActor in
            var projectCopy = self.document // Create a mutable copy of the project
            projectCopy.updatePage(page) // Update the page in the project copy
            self.document = projectCopy
        }

        // Reset drag state
        self.draggedTextElementID = nil
        self.dragOffset = .zero
        self.initialDragPosition = nil
    }

    @MainActor
    private func applySelectedTemplateWithUndo() {
        guard let templateIDString = self.selectedTemplateID,
              let templateUUID = UUID(uuidString: templateIDString),
              let template: AppScreenshotTemplate = TemplateProvider.template(withId: templateUUID) else {
            // print("No template selected or templateID is nil.")
            return
        }

        var newProject = self.document // Create a mutable copy
        guard var currentPage = newProject.activePage else {
            // print("No active page to apply template to.")
            return
        }

        currentPage.textElements = template.textElements.map { config -> TextElementConfig in
            var newConfig = config
            newConfig.id = UUID() // Ensure new unique IDs for template elements
            return newConfig
        }
        currentPage.backgroundStyle = template.backgroundStyle
        // Ensure TemplateDeviceFrame has a `frameType: DeviceFrameType` property
        currentPage.deviceFrameType = template.deviceFrame.deviceType 
        currentPage.deviceFrameOffset = CodableCGSize(size: CGSize(width: template.deviceFrame.offset.x, height: template.deviceFrame.offset.y))
        
        if let templateCanvasSize = template.canvasSize {
            currentPage.canvasSize = templateCanvasSize
        } else {
            currentPage.updateCanvasSizeToDefault() // Ensure this method exists on ScreenshotPage
        }
        // currentPage.importedImage = template.importedImageData // If template carries image data
        
        newProject.updatePage(currentPage) // Update the page in the project copy
        self.document = newProject
    }
    
    // Note: The ColorPicker's set action is now directly within the body's view hierarchy,
    // using document.changeProjectModel.
    // Image import functionality (like `importImageWithUndo`) might be better placed in InspectorView
    // or triggered via a toolbar button that calls a method on `document` or `CanvasView`.
    // For now, it's assumed `InspectorView` handles image import.

    @MainActor
    func exportScreenshot() {
        guard let page = activePage else { // Use the @State activePage
            print("No active page to export.")
            return
        }

        // Define a target height for the device frame in the exported image (in points)
        // This helps maintain a consistent perceived size for the device in exports.
        let exportTargetHeightPoints: CGFloat = 1000 
        
        var finalCanvasSize: CGSize
        var deviceFrameInCanvas: CGRect = .zero // The rect of the device frame within the finalCanvasSize
        var renderedUserScreenshotRect: CGRect = .zero // The rect where user's screenshot is drawn within deviceFrameInCanvas
        var fontScaleFactor: CGFloat = 1.0

        // Ensure device frame image and its screen area details are available
        guard let deviceFrameNsImage = self.deviceFrameImage, // Use computed property
              page.deviceFrameType.deviceType != .custom else {
            print("Export error: Device frame asset missing or not selected.")
            return
        }

        let deviceType = page.deviceFrameType.deviceType
        let screenAreaInAssetPixels = deviceType.screenAreaPixels // Pixels in the original asset

        // Calculations if device frame is present
        if deviceFrameNsImage.size != .zero && screenAreaInAssetPixels != .zero {
            let deviceAspectRatio = deviceFrameNsImage.size.width / deviceFrameNsImage.size.height
            let scaledDeviceHeight = exportTargetHeightPoints
            let scaledDeviceWidth = scaledDeviceHeight * deviceAspectRatio
            
            finalCanvasSize = CGSize(width: scaledDeviceWidth, height: scaledDeviceHeight)
            deviceFrameInCanvas = CGRect(origin: .zero, size: finalCanvasSize)

            // Normalized screen rect within the device frame asset
            let normScreenRect = CGRect(
                x: screenAreaInAssetPixels.origin.x / deviceFrameNsImage.size.width,
                y: screenAreaInAssetPixels.origin.y / deviceFrameNsImage.size.height,
                width: screenAreaInAssetPixels.size.width / deviceFrameNsImage.size.width,
                height: screenAreaInAssetPixels.size.height / deviceFrameNsImage.size.height
            )

            // Calculate the rect for the user's screenshot within the scaled device frame
            renderedUserScreenshotRect = CGRect(
                x: normScreenRect.origin.x * finalCanvasSize.width,
                y: normScreenRect.origin.y * finalCanvasSize.height, // Y is from top in AppKit/Cocoa for drawing
                width: normScreenRect.size.width * finalCanvasSize.width,
                height: normScreenRect.size.height * finalCanvasSize.height
            )
            
            // Font scaling based on MEMORY[048cee8e-310f-4ce1-b05e-c40bbd56c461]
            let referencePreviewScreenHeightPoints: CGFloat = 410.0 // As per memory
            if renderedUserScreenshotRect.height > 0 { // Avoid division by zero
                 fontScaleFactor = renderedUserScreenshotRect.height / referencePreviewScreenHeightPoints
            }

        } else if let userScreenshotImage = self.userScreenshot { // No frame, but screenshot exists
            finalCanvasSize = userScreenshotImage.size
            renderedUserScreenshotRect = CGRect(origin: .zero, size: finalCanvasSize)
            // Font scaling might need a different reference if no device frame context
            fontScaleFactor = 1.0 // Or some other default scaling
        } else {
            print("Export error: No content to export (neither frame nor screenshot).")
            return
        }


        // Construct the view to be rendered
        let exportView = ZStack {
            // Background
            switch page.backgroundStyle {
            case .solid(let codableColor):
                codableColor.color
            case .gradient(let gradientModel):
                LinearGradient(gradient: Gradient(colors: gradientModel.colors.map { $0.color }), startPoint: gradientModel.startPoint.unitPoint, endPoint: gradientModel.endPoint.unitPoint)
            case .image(let imageFill):
                if let imageData = imageFill.imageData, let bgImage = NSImage(data: imageData) {
                    Image(nsImage: bgImage)
                        .resizable()
                        .aspectRatio(contentMode: imageFill.tilingMode == .aspectFit ? .fit : .fill)
                        .frame(width: finalCanvasSize.width, height: finalCanvasSize.height)
                        .clipped()
                } else {
                    Color.gray // Fallback
                }
            }

            // Device Mockup (if frame is available)
            if deviceFrameNsImage.size != .zero && screenAreaInAssetPixels != .zero {
                 DeviceMockupView(
                    userScreenshot: self.userScreenshot, // Use computed property
                    deviceFrameImage: deviceFrameNsImage,
                    screenAreaPixels: screenAreaInAssetPixels, // Original pixel data for the asset
                    screenCornerRadius: self.screenCornerRadius // Use computed property
                )
                .frame(width: finalCanvasSize.width, height: finalCanvasSize.height)
            } else if let justScreenshot = self.userScreenshot { // No frame, just the screenshot
                 Image(nsImage: justScreenshot)
                    .resizable()
                    .aspectRatio(contentMode: .fit) // Fit to finalCanvasSize if it was based on screenshot
                    .frame(width: finalCanvasSize.width, height: finalCanvasSize.height)
            }

            // Text Elements
            ForEach(page.textElements) { textConfig in // Iterate directly over configs
                TextElementView(config: textConfig, fontScaleFactor: fontScaleFactor) // Pass config directly
                    .position(
                        x: (textConfig.positionRatio.x * finalCanvasSize.width) + textConfig.offsetPixels.width,
                        y: (textConfig.positionRatio.y * finalCanvasSize.height) + textConfig.offsetPixels.height
                    )
                    // The TextElementView itself should handle its internal frame and alignment based on its config
            }
        }
        .frame(width: finalCanvasSize.width, height: finalCanvasSize.height)
        .background(Color.clear) // Ensure transparency if background is not full

        // Render the SwiftUI view to an NSImage
        guard let nsImage = exportView.renderAsImage(size: finalCanvasSize) else {
            print("Failed to render screenshot view to image.")
            return
        }

        // Save the image
        let savePanel = NSSavePanel()
        let deviceNameForFile = page.deviceFrameType.deviceType.id.replacingOccurrences(of: " ", with: "_")
        let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        savePanel.nameFieldStringValue = "Screenshot-\(deviceNameForFile)-\(timestamp).png"
        savePanel.allowedContentTypes = [UTType.png] // Use UTType

        if savePanel.runModal() == .OK, let url = savePanel.url {
            guard let tiffData = nsImage.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiffData),
                  let pngData = bitmap.representation(using: NSBitmapImageRep.FileType.png, properties: [:]) else {
                print("Failed to convert rendered image to PNG data.")
                return
            }
            do {
                try pngData.write(to: url)
                print("Screenshot saved to \(url.path)")
            } catch {
                print("Error saving screenshot: \(error.localizedDescription)")
            }
        }
    }
}

// Preview Provider
struct CanvasView_Previews: PreviewProvider {
    static var previewProjectModel: ProjectModel = {
        var model = ProjectModel()
        let page = ScreenshotPage(
            name: "iPhone Preview",
            deviceFrameType: .iPhone15Pro
        )
        model.pages = [page]
        model.activePageID = page.id
        return model
    }()

    static var previews: some View {
        CanvasView(document: .constant(previewProjectModel), selectedTemplateID: .constant(nil as String?))
    }
}