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
        DocumentGroup(newDocument: self.createDocument) { fileConfiguration in
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
                // If you had a .keyboardShortcut("n", modifiers: .command) here, re-add it.
            }

            // Undo/Redo
            CommandGroup(replacing: .undoRedo) {
                Button("Undo") {
                    NSApp.sendAction(Selector(("undo:")), to: nil, from: nil)
                }
                .keyboardShortcut("z", modifiers: .command)

                Button("Redo") {
                     NSApp.sendAction(Selector(("redo:")), to: nil, from: nil)
                }
                .keyboardShortcut("z", modifiers: [.command, .shift])
            }

            /*
            // Optional: Placeholder for Export command if you want to re-add it later
            CommandGroup(after: .saveItem) {
                 Button("Export Project As...") {
                    // This would typically trigger a custom export process.
                    print("Export action triggered from menu. Needs document context.")
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
            }
            */
        }
    }

    @MainActor
    private func createDocument() -> ScreenshotProjectDocument {
        return ScreenshotProjectDocument()
    }
}

