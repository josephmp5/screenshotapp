import SwiftUI
import UniformTypeIdentifiers

// Define a Uniform Type Identifier for our custom project file
extension UTType {
    static var screenshotMakerProject: UTType = UTType(exportedAs: "com.windsurf.screenshotmaker.project")
}

class ScreenshotProjectDocument: ReferenceFileDocument {
    typealias Snapshot = ProjectModel

    @MainActor @Published var project: ProjectModel
    weak var undoManager: UndoManager? // Document's own undo manager

    // MARK: - Undo/Redo Management

    /// The primitive function for setting the project model. This does NOT register an undo action.
    /// - Parameter newModel: The new `ProjectModel` to set.
    @MainActor private func setProjectModel(_ newModel: ProjectModel) {
        self.project = newModel
    }

    /// Performs a change to the project model and registers an undo action.
    /// This is the primary method that views should call to ensure changes are undoable.
    /// - Parameters:
    ///   - newModel: The new state of the `ProjectModel`.
    ///   - actionName: A descriptive name for the change, e.g., "Edit Text", for the Edit menu.
    @MainActor func changeProjectModel(to newModel: ProjectModel, actionName: String) {
        let oldModel = self.project

        // Register the undo action using the document's own undoManager.
        // The closure operates on 'document' (which is 'self'), and 'self' is @MainActor isolated.
        // The recursive call to changeProjectModel uses the new signature.
        self.undoManager?.registerUndo(withTarget: self) { document in
            Task { @MainActor in
                document.changeProjectModel(to: oldModel, actionName: actionName)
            }
        }
        
        // Set the action name for the Edit menu using the document's undoManager.
        if let manager = self.undoManager, manager.isUndoing == false {
            manager.setActionName(actionName)
        }

        // Apply the change for the first time.
        setProjectModel(newModel)
    }

    static var readableContentTypes: [UTType] { [.screenshotMakerProject] }
    static var writableContentTypes: [UTType] { [.screenshotMakerProject, .json] }
    static var defaultContentType: UTType { .screenshotMakerProject }

    @MainActor required init() {
        self.project = ProjectModel()
    }

    @MainActor required init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let decoder = JSONDecoder()
        self.project = try decoder.decode(ProjectModel.self, from: data)
    }

    @MainActor func snapshot(contentType: UTType) throws -> ProjectModel {
        project
    }

    func fileWrapper(snapshot: ProjectModel, configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        let data = try encoder.encode(snapshot)
        return .init(regularFileWithContents: data)
    }
}

