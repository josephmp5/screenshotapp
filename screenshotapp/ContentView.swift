import SwiftUI

struct ContentView: View {
    @ObservedObject var document: ScreenshotProjectDocument
    @Environment(\.undoManager) var undoManager

    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var selectedAppSection: SidebarView.AppSection? = .projects // Default to projects/canvas
    @State private var exportTrigger: UUID? = nil

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(document: document, currentSelection: $selectedAppSection)
                .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 350)
        } content: {
            Group {
                if let section = selectedAppSection {
                    switch section {
                    case .templates:
                        // Placeholder for Template Browser View
                        Text("Templates Browser (Document: \(document.project.id.uuidString.prefix(8)))")
                            .font(.largeTitle)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.purple.opacity(0.1))
                    case .devices:
                        // Placeholder for Device Configuration View
                        Text("Device Configuration (Document: \(document.project.id.uuidString.prefix(8)))")
                            .font(.largeTitle)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.orange.opacity(0.1))
                    case .assets:
                        // Placeholder for Asset Library View
                        Text("Asset Library (Document: \(document.project.id.uuidString.prefix(8)))")
                            .font(.largeTitle)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.yellow.opacity(0.1))
                    case .projects:
                        // The main canvas area is now delegated to CanvasView
                        CanvasView(document: document, exportTrigger: $exportTrigger)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else {
                    ContentUnavailableView("Select an item from the sidebar", systemImage: "sidebar.left")
                }
            }
        } detail: {
            InspectorView(document: document)
                .navigationSplitViewColumnWidth(min: 240, ideal: 280, max: 400)
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                // Save button (contextual, primarily relies on Cmd+S)
                Button(action: {
                    // This is more of a conceptual save button for the toolbar.
                    // Actual save is handled by the document model and File > Save.
                    print("Toolbar Save button tapped. Document: \(document.project.id). Use File > Save.")
                    // If you need to trigger save programmatically for some reason:
                    // NSApp.sendAction(#selector(NSDocument.save(_:)), to: nil, from: nil)
                }) {
                    Label("Save Project", systemImage: "square.and.arrow.down")
                }
                // .disabled(!document.hasUnsavedChanges) // This would require hasUnsavedChanges on ScreenshotProjectDocument

                Divider()

                // Export button
                Button(action: {
                    exportTrigger = UUID()
                    print("Export triggered for document: \(document.project.id)")
                }) {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                // .disabled(true) // TODO: Enable based on content

                Divider()

                // Undo button
                Button(action: {
                    undoManager?.undo()
                }) {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                }
                .disabled(!(undoManager?.canUndo ?? false))

                // Redo button
                Button(action: {
                    undoManager?.redo()
                }) {
                    Label("Redo", systemImage: "arrow.uturn.forward")
                }
                .disabled(!(undoManager?.canRedo ?? false))
            }
        }
        .navigationTitle(selectedAppSection?.rawValue ?? "Screenshot Project")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let document = ScreenshotProjectDocument()
        ContentView(document: document)
        .frame(width: 1200, height: 800)
        .previewDisplayName("ContentView with Document")
    }
}
