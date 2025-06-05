import SwiftUI

struct SidebarView: View {
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

    @Binding var currentSelection: AppSection?

    var body: some View {
        List(selection: $currentSelection) {
            ForEach(AppSection.allCases) { section in
                NavigationLink(value: section) { // Use section directly as value for NavigationSplitView
                    Label(section.rawValue, systemImage: section.iconName)
                }
            }
        }
        .listStyle(.sidebar)
    }
}

// Helper for previews with @Binding. Often good to put in a separate PreviewsHelper.swift file.
struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State var value: Value
    var content: (Binding<Value>) -> Content

    init(_ initialValue: Value, content: @escaping (Binding<Value>) -> Content) {
        self._value = State(initialValue: initialValue)
        self.content = content
    }

    var body: some View {
        content($value)
    }
}

struct SidebarView_Previews: PreviewProvider {
    static var previews: some View {
        StatefulPreviewWrapper(SidebarView.AppSection.templates) { selectionBinding in
            SidebarView(currentSelection: selectionBinding)
        }
        .frame(width: 220)
        .previewDisplayName("Sidebar with Templates Selected")

        StatefulPreviewWrapper(nil) { selectionBinding in
            SidebarView(currentSelection: selectionBinding)
        }
        .frame(width: 220)
        .previewDisplayName("Sidebar with No Selection")
    }
}
