//
//  screenshotappApp.swift
//  screenshotapp
//
//  Created by Yakup Özmavi on 3.06.2025.
//

import SwiftUI

@main
struct screenshotappApp: App {
    // No need for a global undoManager here when using DocumentGroup,
    // as each document scene will get its own in the environment.

    var body: some Scene {
        DocumentGroup(newDocument: { ScreenshotProjectDocument() }) { fileConfiguration in
            ContentView(document: fileConfiguration.document)
            // The UndoManager is automatically available in the environment for DocumentGroup scenes.
            // ContentView will pick it up via @Environment(\.undoManager).
        }
        .commands {
            // Standard document commands (New, Open, Save, Save As, Export, Undo, Redo)
            // are largely handled by DocumentGroup and ReferenceFileDocument.
            // We can customize or add to them here if needed.

            // Example: Customizing "New"
            CommandGroup(replacing: .newItem) {
                Button("New Screenshot Project") {
                    NSDocumentController.shared.newDocument(nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            
            // Example: Adding an explicit Export command to the File menu
            // Note: ReferenceFileDocument doesn't automatically provide an "Export" menu item.
            // You need to add it if your document supports a distinct export operation.
            CommandGroup(after: .saveItem) { // Place it after the standard Save items
                 Button("Export Project As...") {
                    // This would typically trigger a custom export process.
                    // For now, it's a placeholder. The actual export logic
                    // would need access to the current document.
                    print("Export action triggered from menu. Needs document context.")
                    // To get the current document, you might need to use NSApp.currentDocument or similar,
                    // or have the action routed to the focused window's content view.
                }
                .keyboardShortcut("e", modifiers: [.command, .shift]) // Example shortcut
            }

            // Undo/Redo are automatically handled by DocumentGroup if the document
            // correctly uses its undoManager for changes to @Published properties.
            // Explicitly adding them ensures they appear if not automatically present
            // or allows customization of their placement/text.
            CommandGroup(replacing: .undoRedo) {
                Button("Undo") {
                    NSApp.sendAction(Selector(("undo:")), to: nil, from: nil)
                }
                .keyboardShortcut("z", modifiers: .command)
                // Disabling state is typically handled by the system based on undoManager.canUndo

                Button("Redo") {
                     NSApp.sendAction(Selector(("redo:")), to: nil, from: nil)
                }
                .keyboardShortcut("z", modifiers: [.command, .shift])
                // Disabling state is typically handled by the system based on undoManager.canRedo
            }
        }
    }
}

