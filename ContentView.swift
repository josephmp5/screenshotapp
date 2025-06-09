import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var importedImage: NSImage? = nil
    @State private var selectedDevice: DeviceType = .iPhone
    @State private var backgroundColor: Color = .gray
    @State private var textOverlay: String = "Sample Text"

    enum DeviceType: String, CaseIterable, Identifiable {
        case iPhone = "iPhone"
        case iPad = "iPad"
        case mac = "Mac"
        var id: String { self.rawValue }
    }

    var body: some View {
        HSplitView {
            // Controls Panel
            VStack(alignment: .leading, spacing: 20) {
                Text("Screenshot Maker")
                    .font(.largeTitle)
                    .padding(.bottom)

                // 1. Image Importer
                Button(action: {
                    importImage()
                }) {
                    Text(importedImage == nil ? "Import Screenshot" : "Replace Screenshot")
                }
                .padding()

                if importedImage != nil {
                    Image(nsImage: importedImage!)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 200, maxHeight: 200)
                        .border(Color.gray)
                }

                // 2. Device Mockup Selector Placeholder
                Picker("Device", selection: $selectedDevice) {
                    ForEach(DeviceType.allCases) {
                        Text($0.rawValue).tag($0)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                // 3. Background Customization Placeholder
                ColorPicker("Background Color", selection: $backgroundColor)

                // 4. Text Overlay Placeholder
                TextField("Overlay Text", text: $textOverlay)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Spacer()
                
                // 5. Export Button
                Button(action: {
                    exportScreenshot()
                }) {
                    Text("Export Screenshot")
                }
                .padding()
                .disabled(importedImage == nil) // Disable if no image

            }
            .padding()
            .frame(minWidth: 250, idealWidth: 300, maxWidth: 400)

            // Preview Panel
            DeviceMockupView(image: importedImage, deviceType: selectedDevice, backgroundColor: backgroundColor, textOverlay: textOverlay)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 800, minHeight: 600)
    }

    private func importImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg] // Allow PNG and JPEG
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK {
            if let url = panel.url {
                importedImage = NSImage(contentsOf: url)
            }
        }
    }

    private func exportScreenshot() {
        guard importedImage != nil else {
            print("No image to export.")
            return
        }

        let exportWidth: CGFloat = 2796
        let exportHeight: CGFloat = 1290
        
        let viewToRender = DeviceMockupView(
            image: importedImage,
            deviceType: selectedDevice,
            backgroundColor: backgroundColor,
            textOverlay: textOverlay
        )
        .frame(width: exportWidth, height: exportHeight) // Ensure the view is rendered at the target export size

        guard let imageToExport = viewToRender.renderAsImage(size: NSSize(width: exportWidth, height: exportHeight)) else {
            print("Failed to render image for export.")
            return
        }

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [UTType.png]
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = "Screenshot-\(selectedDevice.rawValue)-\(String(format: "%.0f", Date().timeIntervalSince1970)).png"

        if savePanel.runModal() == .OK {
            if let url = savePanel.url {
                guard let tiffData = imageToExport.tiffRepresentation,
                      let bitmap = NSBitmapImageRep(data: tiffData),
                      let pngData = bitmap.representation(using: .png, properties: [:]) else {
                    print("Failed to convert image to PNG.")
                    return
                }
                do {
                    try pngData.write(to: url)
                    print("Image saved to \\(url)")
                } catch {
                    print("Failed to save image: \\(error)")
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
