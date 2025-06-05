import SwiftUI
import UniformTypeIdentifiers // For export and import panels

// Assuming DeviceMockupView, TemplateProvider, and View+Render.swift (for .renderAsImage) exist.

struct CanvasView: View {
    @ObservedObject var document: ScreenshotProjectDocument
    @Environment(\.undoManager) var undoManager
    @Binding var exportTrigger: UUID?

    // State for UI controls that might not be directly in the document model yet,
    // or are transient for the current editing session.
    @State private var importedImage: NSImage? = nil // The actual image data for the screenshot
    @State private var selectedDevice: DeviceType = .iPhone // Current device mockup
    // backgroundColor will now primarily be driven by document.project.canvasBackgroundColor
    @State private var textOverlay: String = "Sample Text"
    @State private var selectedTemplateID: UUID? = TemplateProvider.templates.first?.id
    @State private var textColor: Color = .white
    @State private var textAlignment: Alignment = .bottom
    @State private var selectedFontName: String = "System Font"
    @State private var selectedFontSize: CGFloat = 18

    let availableFontNames: [String] = ["System Font", "Helvetica Neue", "Avenir Next", "Gill Sans", "Futura", "Times New Roman", "Courier New"]

    // For pan and zoom (placeholders, not fully implemented from original CanvasView)
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero


    var body: some View {
        HSplitView {
            // Controls Panel (similar to what was in ContentView's .projects case)
            VStack(alignment: .leading, spacing: 15) { // Adjusted spacing
                Text("Canvas Controls")
                    .font(.title2) // Adjusted font
                    .padding(.bottom, 5)

                // 1. Image Importer
                Button(action: {
                    importImageWithUndo()
                }) {
                    Text(importedImage == nil ? "Import Screenshot" : "Replace Screenshot")
                }
                .padding(.vertical, 5)

                if importedImage != nil {
                    Image(nsImage: importedImage!)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 200, maxHeight: 150) // Adjusted frame
                        .border(Color.gray)
                        .padding(.bottom, 5)
                }

                // Template Selector
                Picker("Template", selection: $selectedTemplateID) {
                    ForEach(TemplateProvider.templates) { template in
                        Text(template.name).tag(template.id as UUID?)
                    }
                }
                .onChange(of: selectedTemplateID) { _ in // SwiftUI 3+ syntax
                    applySelectedTemplateWithUndo()
                }
                .padding(.bottom, 5)

                // 2. Device Mockup Selector
                Picker("Device", selection: $selectedDevice) { // TODO: Make this undoable if it modifies document state
                    ForEach(DeviceType.allCases) {
                        Text($0.rawValue).tag($0)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.bottom, 5)
                
                // 3. Background Customization (Now directly modifies the document)
                ColorPicker("Background Color", selection: Binding(
                    get: { document.project.canvasBackgroundColor.color },
                    set: { newColor in
                        changeBackgroundColorWithUndo(to: newColor)
                    }
                ))
                .padding(.bottom, 5)

                // 4. Text Overlay
                TextField("Overlay Text", text: $textOverlay) // TODO: Make this undoable if it modifies document state
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.bottom, 5)

                // Font Controls
                Picker("Font", selection: $selectedFontName) { // TODO: Make this undoable
                    ForEach(availableFontNames, id: \.self) {
                        Text($0).font(.custom($0, size: 14))
                    }
                }
                Stepper("Font Size: \(Int(selectedFontSize))", value: $selectedFontSize, in: 10...72) // TODO: Make this undoable
                
                Spacer()
                
                // 5. Export Button
                Button(action: {
                    exportScreenshot()
                }) {
                    Text("Export Screenshot")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.vertical, 10)
                .disabled(importedImage == nil)

            }
            .padding()
            .frame(minWidth: 280, idealWidth: 320, maxWidth: 400) // Adjusted width

            // Preview Panel (DeviceMockupView)
            ZStack { // Use ZStack for background color from document
                document.project.canvasBackgroundColor.color
                    .edgesIgnoringSafeArea(.all)

                DeviceMockupView(
                    image: importedImage,
                    deviceType: selectedDevice,
                    backgroundColor: .clear, // Background is handled by ZStack above
                    textOverlay: textOverlay,
                    textColor: textColor,
                    textAlignment: textAlignment,
                    fontName: selectedFontName,
                    fontSize: selectedFontSize
                )
                .scaleEffect(scale)
                .offset(offset)
                // TODO: Add pan/zoom gestures here, updating @State scale and offset
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped() // Important for pan/zoom
        }
        .onAppear {
            // When CanvasView appears, apply the default or current document's template settings.
            applySelectedTemplateWithUndo(isInitialAppearance: true)
        }
        .onChange(of: exportTrigger) { newValue in
            if newValue != nil {
                print("CanvasView: Export triggered by ContentView.")
                exportScreenshot()
                exportTrigger = nil // Reset the trigger
            }
        }
    }

    // MARK: - Undoable Actions

    private func changeBackgroundColorWithUndo(to newUIColor: Color) {
        let oldCodableColor = document.project.canvasBackgroundColor
        let newCodableColor = CodableColor(color: newUIColor)
        
        guard oldCodableColor.color != newCodableColor.color else { return }

        document.project.canvasBackgroundColor = newCodableColor
        
        undoManager?.registerUndo(withTarget: document, handler: { doc in
            document.project.canvasBackgroundColor = oldCodableColor
        })
        undoManager?.setActionName("Change Background Color")
    }
    
    private func importImageWithUndo() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .heic]
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK {
            if let url = panel.url {
                // For @State variable:
                self.importedImage = NSImage(contentsOf: url)
                
                // If importedImage were part of document.project, you'd do:
                // let oldImageData = document.project.imageData
                // document.project.imageData = try? Data(contentsOf: url)
                // undoManager?.registerUndo(withTarget: document) { doc in
                //     doc.snapshot.imageData = oldImageData
                // }
                // undoManager?.setActionName("Import Image")
            }
        }
    }

    private func applySelectedTemplateWithUndo(isInitialAppearance: Bool = false) {
        guard let templateID = selectedTemplateID,
              let template = TemplateProvider.templates.first(where: { $0.id == templateID }) else {
            return
        }

        let oldSelectedDevice = self.selectedDevice
        let oldBackgroundColorOfDocument = document.project.canvasBackgroundColor
        let oldTextOverlay = self.textOverlay
        let oldTextColor = self.textColor
        let oldTextAlignment = self.textAlignment
        let oldFontName = self.selectedFontName
        let oldFontSize = self.selectedFontSize
        // let oldImportedImage = self.importedImage // If template could change the image

        // Apply template values to @State properties
        self.selectedDevice = template.deviceType
        self.textOverlay = template.textOverlay
        self.textColor = template.textColor
        self.textAlignment = template.textAlignment
        self.selectedFontName = template.fontName
        self.selectedFontSize = template.fontSize
        // self.importedImage = template.previewImage // If template provides a default/preview image

        // Apply background color from template to the document (this will use its own undo)
        if document.project.canvasBackgroundColor.color != template.backgroundColor {
             changeBackgroundColorWithUndo(to: template.backgroundColor)
        }

        if !isInitialAppearance {
            // Group subsequent changes under one undo action name if possible,
            // or register a single encompassing undo action.
            // For simplicity here, we rely on changeBackgroundColorWithUndo's own registration.
            // A more complex template application might require a single undo block.
            
            // Register undo for the @State changes in CanvasView
            // This needs to target 'self' (CanvasView) or a proxy object if undoManager is document's.
            // A common pattern is to have the document manage all undoable state.
            // For now, this demonstrates a conceptual undo for @State properties.
            undoManager?.registerUndo(withTarget: document, handler: { [self] _ in // Capture self for @State restoration
                self.selectedDevice = oldSelectedDevice
                // document.project.canvasBackgroundColor is handled by its own undo.
                // If we didn't want that, we'd restore it here:
                // document.project.canvasBackgroundColor = oldBackgroundColorOfDocument
                self.textOverlay = oldTextOverlay
                self.textColor = oldTextColor
                self.textAlignment = oldTextAlignment
                self.selectedFontName = oldFontName
                self.selectedFontSize = oldFontSize
                // self.importedImage = oldImportedImage

                // Potentially re-select the previous templateID if applying a template
                // is a distinct action from just setting properties.
            })
            undoManager?.setActionName("Apply Template: \(template.name)")
        }
    }


    // MARK: - Export
    private func exportScreenshot() {
        guard importedImage != nil else {
            print("No image to export.")
            return
        }

        let exportWidth: CGFloat
        let exportHeight: CGFloat
        let renderScaleFactor: CGFloat = 1.0 

        switch selectedDevice {
        case .iPhone: 
            exportWidth = 390 * renderScaleFactor 
            exportHeight = 844 * renderScaleFactor
        case .iPad:
            exportWidth = 820 * renderScaleFactor
            exportHeight = 1180 * renderScaleFactor
        case .mac:
            exportWidth = 1280 * renderScaleFactor
            exportHeight = 800 * renderScaleFactor
        }
        
        let viewToRender = DeviceMockupView(
            image: importedImage,
            deviceType: selectedDevice,
            backgroundColor: .clear, 
            textOverlay: textOverlay,
            textColor: textColor,
            textAlignment: textAlignment,
            fontName: selectedFontName,
            fontSize: selectedFontSize
        )
        .background(document.project.canvasBackgroundColor.color) // Ensure document bg is part of export
        .frame(width: exportWidth, height: exportHeight)
        .environment(\.colorScheme, .light) // Consistent rendering environment

        guard let imageToExport = viewToRender.renderAsImage(size: NSSize(width: exportWidth, height: exportHeight)) else {
            print("Failed to render image for export.")
            return
        }

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [UTType.png, UTType.jpeg]
        savePanel.canCreateDirectories = true
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd-HHmmss"
        let dateString = dateFormatter.string(from: Date())
        savePanel.nameFieldStringValue = "Screenshot-\(selectedDevice.rawValue)-\(dateString).png"

        if savePanel.runModal() == .OK {
            if let url = savePanel.url {
                guard let tiffData = imageToExport.tiffRepresentation,
                      let bitmap = NSBitmapImageRep(data: tiffData) else {
                    print("Failed to get TIFF representation of image.")
                    return
                }
                
                let fileType: NSBitmapImageRep.FileType = url.pathExtension.lowercased() == "jpg" || url.pathExtension.lowercased() == "jpeg" ? .jpeg : .png
                let properties: [NSBitmapImageRep.PropertyKey: Any] = fileType == .jpeg ? [.compressionFactor: 0.9] : [:]

                guard let imageData = bitmap.representation(using: fileType, properties: properties) else {
                    print("Failed to convert image to \(fileType == .jpeg ? "JPEG" : "PNG").")
                    return
                }
                
                do {
                    try imageData.write(to: url)
                    print("Image saved to \(url)")
                } catch {
                    print("Error saving image: \(error.localizedDescription)")
                }
            }
        }
    }
}


struct CanvasView_Previews: PreviewProvider {
    static var previews: some View {
        let document = ScreenshotProjectDocument()
        CanvasView(document: document, exportTrigger: .constant(nil))
        .frame(width: 1000, height: 700)
        .previewDisplayName("CanvasView with Document")
    }
}

// MARK: - View+Render Extension (Ensure this is in your project, e.g., in View+Render.swift)
/*
import SwiftUI

extension View {
    func renderAsImage(size: NSSize) -> NSImage? {
        let controller = NSHostingController(rootView: self.frame(width: size.width, height: size.height))
        let targetView = controller.view
        targetView.frame = CGRect(origin: .zero, size: size)
        targetView.layoutSubtreeIfNeeded() // Ensure layout is complete

        guard let bitmapRep = targetView.bitmapImageRepForCachingDisplay(in: targetView.bounds) else {
            print("Failed to create bitmapImageRep for caching display.")
            return nil
        }
        
        targetView.cacheDisplay(in: targetView.bounds, to: bitmapRep)
        
        guard let cgImage = bitmapRep.cgImage else {
            print("Failed to get CGImage from bitmapRep.")
            return nil
        }
        
        return NSImage(cgImage: cgImage, size: size)
    }
}
*/