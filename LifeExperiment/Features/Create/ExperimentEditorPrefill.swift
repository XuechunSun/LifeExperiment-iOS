import Foundation

struct ExperimentEditorPrefill: Identifiable {
    let id = UUID()
    let title: String
    let categoryTitle: String?
    let subcategoryTitle: String?
}
