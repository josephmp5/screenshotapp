import SwiftUI

/// The main view of the application, organizing the UI into a three-column layout.
struct ContentView: View {
    @ObservedObject var document: ScreenshotProjectDocument
    @Environment(\.undoManager) var undoManager

    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var selectedAppSection: SidebarView.AppSection? = .projects // Default to projects/canvas
    @State private var selectedTemplateID: String? = nil

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // --- Sidebar (Left Panel) ---
            SidebarView(document: document, currentSelection: $selectedAppSection)
                .navigationSplitViewColumnWidth(min: 220, ideal: 250)
        } content: {
            // --- Canvas (Main Content Area) ---
            Group {
                if let section = selectedAppSection {
                    switch section {
                    case .projects:
                        CanvasView(document: $document.project, selectedTemplateID: $selectedTemplateID)
                    case .templates:
                        // Placeholder for Template Browser View
                        Text("Templates Browser")
                    case .devices:
                        // Placeholder for Device Browser View
                        Text("Device Browser")
                    case .assets:
                        // Placeholder for Assets Browser View
                        Text("Assets Browser")
                    }
                } else {
                    Text("Select a section from the sidebar.")
                }
            }
            .navigationSplitViewColumnWidth(min: 400, ideal: 600)
        } detail: {
            // --- Inspector (Right Panel) ---
            InspectorView(document: document)
                .navigationSplitViewColumnWidth(min: 250, ideal: 300)
        }
        .onAppear {
            // Assign the environment's undo manager to the document
            document.undoManager = self.undoManager
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
                    // exportTrigger = UUID()
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
        .navigationTitle("Screenshot App")
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
