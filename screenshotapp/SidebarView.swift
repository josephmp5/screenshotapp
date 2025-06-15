import SwiftUI

struct SidebarView: View {
    @Environment(\.undoManager) var envUndoManager
    @ObservedObject var document: ScreenshotProjectDocument
    // Define AppSection inside SidebarView. MainView can refer to it as SidebarView.AppSection.
    enum AppSection: String, CaseIterable, Identifiable {
        case templates = "Templates"
        case devices = "Devices"
        case assets = "Assets"
        case projects = "Projects" // Represents the main project editing/canvas area

        var id: String { self.rawValue }

        var iconName: String {
            switch self {
            case .templates: "square.grid.2x2.fill" // Using filled icons for selection clarity
            case .devices: "macbook.and.iphone"
            case .assets: "photo.on.rectangle.angled"
            case .projects: "doc.text.image"
            }
        }
    }

    @Binding var currentSelection: AppSection? // For general app sections like Templates, Devices

    // AppSection enum remains the same

    var body: some View {
        VStack(alignment: .leading) {
            Text("Project Sections")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding([.leading, .top])

            List(selection: $currentSelection) {
                ForEach(AppSection.allCases) { section in
                    NavigationLink(value: section) {
                        Label(section.rawValue, systemImage: section.iconName)
                    }
                }
            }
            .listStyle(.sidebar)
            .frame(maxHeight: AppSection.allCases.count > 0 ? CGFloat(AppSection.allCases.count * 40) : 100) // Limit height of this list

            Divider()
            
            Text("Pages")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding([.leading, .top])

            List(selection: $document.project.activePageID) { // Bind selection to activePageID
                ForEach($document.project.pages) { $page in // Use binding to allow renaming later
                    HStack {
                        // Simple text for now, can be enhanced with TextField for renaming
                        Text(page.name ?? "Page \(document.project.pages.firstIndex(where: { $0.id == page.id }).map { $0 + 1 } ?? 0)")
                        Spacer()
                        // Optionally show a small icon or indicator if it's the active page
                        if page.id == document.project.activePageID {
                            Image(systemName: "smallcircle.filled.circle")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .tag(page.id) // Important for selection binding
                    .contextMenu {
                        Button("Rename Page") { /* Placeholder for rename action */ }
                        Button("Duplicate Page") { /* Placeholder for duplicate action */ }
                        Divider()
                        Button("Delete Page", systemImage: "trash", role: .destructive) {
                            let pageIDToDelete = page.id
                            let originalPages = document.project.pages
                            let originalActiveID = document.project.activePageID
                            
                            // Register undo before deleting
                            // Ensure pageToDelete exists before attempting to register undo for it, though we capture the whole pages array.
                            if document.project.pages.first(where: { $0.id == pageIDToDelete }) != nil {
                                let um = envUndoManager // Assign to local constant
                                um?.registerUndo(withTarget: document, handler: { doc in
                                    Task { @MainActor in
                                        doc.project.pages = originalPages
                                        doc.project.activePageID = originalActiveID
                                        // The document wrapper should handle necessary updates/publishing.
                                    }
                                })
                                um?.setActionName("Delete Page")
                            }
                            Task { @MainActor in
                                document.project.removePage(withID: pageIDToDelete)
                            }
                        }
                    }
                }
            }
            .listStyle(.sidebar)

            HStack {
                Spacer()
                Button(action: {
                    // Register undo before adding
                    let um = envUndoManager // Assign to local constant
                    if let undoManager = um {
                        let originalPages = document.project.pages
                        let originalActiveID = document.project.activePageID
                        // Register undo with the document as the target
                        undoManager.registerUndo(withTarget: document) { doc in
                            Task { @MainActor in
                                doc.project.pages = originalPages
                                doc.project.activePageID = originalActiveID
                            }
                        }
                        undoManager.setActionName("Add Page")
                    }
                    Task { @MainActor in
                        document.project.addNewPage()
                    }
                }) {
                    Label("Add Page", systemImage: "plus.circle.fill")
                }
                .padding([.bottom, .trailing])
            }
        }
    }
}



struct SidebarView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a dummy document for preview
        let previewDocument = ScreenshotProjectDocument()
        // Add a couple of pages for the preview
        previewDocument.project.addNewPage(name: "Sample Page 2")
        previewDocument.project.addNewPage(name: "Sample Page 3")

        return StatefulPreviewWrapper(SidebarView.AppSection.projects) { selectionBinding in
            SidebarView(document: previewDocument, currentSelection: selectionBinding)
        }
        .frame(width: 250)
        .previewDisplayName("Sidebar with Pages")
    }
}
