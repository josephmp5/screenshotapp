import SwiftUI
import UniformTypeIdentifiers

// Define a Uniform Type Identifier for our custom project file
extension UTType {
    static var screenshotMakerProject: UTType = UTType(exportedAs: "com.windsurf.screenshotmaker.project")
}

@MainActor
class ScreenshotProjectDocument: ReferenceFileDocument {
    typealias Snapshot = ProjectModel

    @Published var project: ProjectModel

    static var readableContentTypes: [UTType] { [.screenshotMakerProject] }
    static var writableContentTypes: [UTType] { [.screenshotMakerProject, .json] }
    static var defaultContentType: UTType { .screenshotMakerProject }

    required init() {
        self.project = ProjectModel()
    }

    required init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let decoder = JSONDecoder()
        self.project = try decoder.decode(ProjectModel.self, from: data)
    }

    func snapshot(contentType: UTType) throws -> ProjectModel {
        project
    }

    func fileWrapper(snapshot: ProjectModel, configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        let data = try encoder.encode(snapshot)
        return .init(regularFileWithContents: data)
    }
}

