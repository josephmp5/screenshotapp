import SwiftUI
import PhotosUI

struct ImageBackgroundEditorView: View {
    @ObservedObject var document: ScreenshotProjectDocument
    @Environment(\.undoManager) var undoManager

    @State private var selectedPhotoItem: PhotosPickerItem? = nil

    // Computed property for the current ImageBackgroundModel from the active page
    private var currentImageModel: ImageBackgroundModel? {
        guard let activePage = document.project.activePage, 
              case .image(let model) = activePage.backgroundStyle else {
            return nil
        }
        return model
    }

    var body: some View {
        // Ensure this view is only interactive if there's an active page with an image background.
        // The InspectorView should manage showing this view appropriately.
        // We can add a guard here for safety, or rely on InspectorView's logic.
        guard let activePage = document.project.activePage, activePage.backgroundStyle.isImage else {
            Text("No image background selected for the active page.")
                .foregroundColor(.gray)
                .padding()
            return AnyView(EmptyView()) // Or some placeholder. Return type erased for guard.
        }

        // Since we guarded, we can now use a non-optional binding if we construct it carefully.
        // Or, continue to use optional chaining if preferred, but the guard makes it safer.
        // For simplicity, let's make bindings that operate directly on the active page's model.

        return AnyView(VStack(alignment: .leading, spacing: 15) {
            Text("Image Settings")
                .font(.headline)

            PhotosPicker(
                selection: $selectedPhotoItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                HStack {
                    Image(systemName: "photo.on.rectangle.angled")
                    Text(currentImageModel?.imageData == nil ? "Select Image" : "Change Image")
                }
            }
            .onChange(of: selectedPhotoItem) { newItem in // newItem is PhotosPickerItem?
                Task {
                    guard let item = newItem else { // item is PhotosPickerItem (unwrapped)
                        return
                    }
                    do {
                        if let data = try await item.loadTransferable(type: Data.self) {
                            guard var pageToUpdate = document.project.activePage else {
                                print("ImageBackgroundEditorView.onChange: No active page to update image.")
                                return
                            }
                            
                            let oldPageBackgroundStyle = pageToUpdate.backgroundStyle
                            let pageID = pageToUpdate.id // Capture pageID for undo

                            var imageModelToUpdate: ImageBackgroundModel
                            if case .image(let model) = pageToUpdate.backgroundStyle {
                                imageModelToUpdate = model
                            } else {
                                // This case should ideally not be reached if InspectorView correctly manages visibility.
                                // If it is, we're changing the background type to image.
                                imageModelToUpdate = ImageBackgroundModel()
                            }
                            imageModelToUpdate.imageData = data
                            pageToUpdate.backgroundStyle = .image(imageModelToUpdate)
                            document.project.activePage = pageToUpdate // This updates the project model
                            
                            undoManager?.registerUndo(withTarget: document, handler: { doc in
                                if var targetPage = doc.project.pages.first(where: { $0.id == pageID }) {
                                     targetPage.backgroundStyle = oldPageBackgroundStyle
                                     doc.project.updatePage(targetPage) // Assumes ProjectModel has updatePage
                                } else {
                                     // Fallback if page was deleted or ID changed
                                }
                            })
                            undoManager?.setActionName("Select Background Image")
                        }
                    } catch {
                        print("Failed to load image data: \(error.localizedDescription)")
                        // Optionally clear selectedPhotoItem to allow re-selection
                        // selectedPhotoItem = nil 
                    }
                }
            }

            if let imageData = currentImageModel?.imageData, let nsImage = NSImage(data: imageData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 100)
                    .cornerRadius(8)
                    .padding(.vertical, 5)
            } else {
                Text("No image selected.")
                    .foregroundColor(.gray)
                    .frame(height: 100)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.vertical, 5)
            }

            // Bindings for TilingMode and Opacity
            // These need to read from and write to the activePage's ImageBackgroundModel
            Picker("Tiling Mode", selection: tilingModeBinding) {
                ForEach(ImageTilingMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(MenuPickerStyle())

            HStack {
                Text("Opacity")
                Slider(value: opacityBinding, in: 0...1)
                Text("\(Int((currentImageModel?.opacity ?? 1.0) * 100))%")
                    .frame(width: 40, alignment: .trailing)
            }
        }
        .padding())
    }

    // Specific binding for tilingMode
    private var tilingModeBinding: Binding<ImageTilingMode> {
        Binding<ImageTilingMode>(
            get: {
                guard let model = currentImageModel else { return .aspectFill } // Default
                return model.tilingMode
            },
            set: { newMode in
                guard var pageToUpdate = document.project.activePage, 
                      case .image(var imageModel) = pageToUpdate.backgroundStyle else { return }
                
                let oldPageBackgroundStyle = pageToUpdate.backgroundStyle
                let pageID = pageToUpdate.id

                imageModel.tilingMode = newMode
                pageToUpdate.backgroundStyle = .image(imageModel)
                document.project.activePage = pageToUpdate

                undoManager?.registerUndo(withTarget: document, handler: { doc in
                    if var targetPage = doc.project.pages.first(where: { $0.id == pageID }) {
                        targetPage.backgroundStyle = oldPageBackgroundStyle
                        doc.project.updatePage(targetPage)
                    }
                })
                undoManager?.setActionName("Change Tiling Mode")
            }
        )
    }

    // Specific binding for opacity
    private var opacityBinding: Binding<Double> {
        Binding<Double>(
            get: {
                guard let model = currentImageModel else { return 1.0 } // Default
                return model.opacity
            },
            set: { newOpacity in
                guard var pageToUpdate = document.project.activePage, 
                      case .image(var imageModel) = pageToUpdate.backgroundStyle else { return }

                let oldPageBackgroundStyle = pageToUpdate.backgroundStyle
                let pageID = pageToUpdate.id

                imageModel.opacity = newOpacity
                pageToUpdate.backgroundStyle = .image(imageModel)
                document.project.activePage = pageToUpdate

                undoManager?.registerUndo(withTarget: document, handler: { doc in
                    if var targetPage = doc.project.pages.first(where: { $0.id == pageID }) {
                        targetPage.backgroundStyle = oldPageBackgroundStyle
                        doc.project.updatePage(targetPage)
                    }
                })
                undoManager?.setActionName("Change Image Opacity")
            }
        )
    }
}

struct ImageBackgroundEditorView_Previews: PreviewProvider {
    static var previews: some View {
        let doc = ScreenshotProjectDocument()
        // Setup an active page with an image background for the preview
        if doc.project.pages.isEmpty {
            var initialPage = ScreenshotPage(name: "Preview Page")
            initialPage.backgroundStyle = .image(ImageBackgroundModel(imageData: nil, tilingMode: .aspectFill, opacity: 0.8))
            doc.project.pages.append(initialPage)
            doc.project.activePageID = initialPage.id
        } else {
            if var activePage = doc.project.activePage { // Use the computed property setter
                activePage.backgroundStyle = .image(ImageBackgroundModel(imageData: nil, tilingMode: .aspectFill, opacity: 0.8))
                doc.project.activePage = activePage
            }
        }
        
        return ImageBackgroundEditorView(document: doc)
            .frame(width: 300)
            .padding()
    }
}
