import SwiftUI
import PhotosUI // For PhotosPicker

struct ImageBackgroundEditorView: View {
    @ObservedObject var document: ScreenshotProjectDocument
    @Environment(\.undoManager) var undoManager

    // Binding to the ImageBackgroundModel within the document's backgroundStyle
    private var imageModelBinding: Binding<ImageBackgroundModel> {
        Binding<ImageBackgroundModel>(
            get: {
                if case .image(let model) = document.project.backgroundStyle {
                    return model
                }
                assertionFailure("ImageBackgroundEditorView.imageModelBinding.get accessed when backgroundStyle is not .image")
                return ImageBackgroundModel(imageData: nil, tilingMode: .aspectFill, opacity: 1.0) // Default/fallback
            },
            set: { newModel in
                if case .image(let oldModel) = document.project.backgroundStyle {
                    if oldModel.imageData != newModel.imageData || oldModel.tilingMode != newModel.tilingMode || oldModel.opacity != newModel.opacity {
                        let oldStyle = document.project.backgroundStyle
                        document.project.backgroundStyle = .image(newModel)
                        
                        undoManager?.registerUndo(withTarget: document, handler: { doc in
                            doc.project.backgroundStyle = oldStyle
                        })
                        undoManager?.setActionName("Change Image Background")
                    }
                }
            }
        )
    }
    
    @State private var selectedPhotoItem: PhotosPickerItem? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Image Settings")
                .font(.headline)

            PhotosPicker(
                selection: $selectedPhotoItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                HStack {
                    Image(systemName: "photo.on.rectangle.angled")
                    Text(imageModelBinding.wrappedValue.imageData == nil ? "Select Image" : "Change Image")
                }
            }
            .onChange(of: selectedPhotoItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        let oldModel = imageModelBinding.wrappedValue
                        var newModel = oldModel
                        newModel.imageData = data
                        
                        let oldStyle = document.project.backgroundStyle
                        document.project.backgroundStyle = .image(newModel)
                        
                        undoManager?.registerUndo(withTarget: document, handler: { doc in
                            doc.project.backgroundStyle = oldStyle
                        })
                        undoManager?.setActionName("Select Background Image")
                    } else {
                        print("Failed to load image data or no item selected.")
                    }
                }
            }

            if let imageData = imageModelBinding.wrappedValue.imageData, let nsImage = NSImage(data: imageData) {
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

            Picker("Tiling Mode", selection: tilingModeBinding) {
                ForEach(ImageTilingMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(MenuPickerStyle())

            HStack {
                Text("Opacity")
                Slider(value: opacityBinding, in: 0...1)
                Text("\(Int(imageModelBinding.wrappedValue.opacity * 100))%")
                    .frame(width: 40, alignment: .trailing)
            }
        }
        .padding()
    }

    private var tilingModeBinding: Binding<ImageTilingMode> {
        Binding<ImageTilingMode>(
            get: { imageModelBinding.wrappedValue.tilingMode },
            set: { newTilingMode in
                let oldModel = imageModelBinding.wrappedValue
                if oldModel.tilingMode != newTilingMode {
                    var newModel = oldModel
                    newModel.tilingMode = newTilingMode
                    
                    let oldStyle = document.project.backgroundStyle
                    document.project.backgroundStyle = .image(newModel)
                    
                    undoManager?.registerUndo(withTarget: document, handler: { doc in
                        doc.project.backgroundStyle = oldStyle
                    })
                    undoManager?.setActionName("Change Image Tiling")
                }
            }
        )
    }

    private var opacityBinding: Binding<Double> {
        Binding<Double>(
            get: { imageModelBinding.wrappedValue.opacity },
            set: { newOpacity in
                let oldModel = imageModelBinding.wrappedValue
                if abs(oldModel.opacity - newOpacity) > 0.001 {
                    var newModel = oldModel
                    newModel.opacity = newOpacity
                    
                    let oldStyle = document.project.backgroundStyle
                    document.project.backgroundStyle = .image(newModel)
                    
                    undoManager?.registerUndo(withTarget: document, handler: { doc in
                        doc.project.backgroundStyle = oldStyle
                    })
                    undoManager?.setActionName("Change Image Opacity")
                }
            }
        )
    }
}

struct ImageBackgroundEditorView_Previews: PreviewProvider {
    static var previews: some View {
        let doc = ScreenshotProjectDocument()
        doc.project.backgroundStyle = .image(ImageBackgroundModel(imageData: nil, tilingMode: .aspectFill, opacity: 0.8))
        
        return ImageBackgroundEditorView(document: doc)
            .frame(width: 300)
            .padding()
    }
}
