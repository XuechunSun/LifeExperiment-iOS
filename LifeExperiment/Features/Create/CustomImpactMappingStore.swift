import SwiftUI
import Foundation
import Combine

@MainActor
final class CustomImpactMappingStore: ObservableObject {
    @AppStorage("customImpactByCategorySubcategoryData") private var data: Data = Data() {
        didSet {
            syncFromExternalIfNeeded()
        }
    }

    @Published private(set) var map: [String: ExperimentImpact] = [:]

    private var didLoad = false
    private var isPersisting = false

    func loadIfNeeded() {
        guard !didLoad else { return }
        map = decode(data)
        didLoad = true
    }

    func suggestedImpact(categoryKey: String, subcategoryText: String) -> ExperimentImpact? {
        let key = mappingKey(categoryKey: categoryKey, subcategoryText: subcategoryText)
        guard !key.isEmpty else { return nil }
        return map[key]
    }

    func saveImpact(_ impact: ExperimentImpact, categoryKey: String, subcategoryText: String) {
        let key = mappingKey(categoryKey: categoryKey, subcategoryText: subcategoryText)
        guard !key.isEmpty else { return }
        map[key] = impact
        persist()
    }

    func syncFromExternalIfNeeded() {
        guard didLoad, !isPersisting else { return }
        let decoded = decode(data)
        if decoded != map {
            map = decoded
        }
    }

    private func mappingKey(categoryKey: String, subcategoryText: String) -> String {
        let category = categoryKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = subcategoryText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !category.isEmpty, !normalized.isEmpty else { return "" }
        return "\(category)|\(normalized)"
    }

    private func decode(_ data: Data) -> [String: ExperimentImpact] {
        guard !data.isEmpty else { return [:] }
        return (try? JSONDecoder().decode([String: ExperimentImpact].self, from: data)) ?? [:]
    }

    private func persist() {
        isPersisting = true
        data = (try? JSONEncoder().encode(map)) ?? Data()
        DispatchQueue.main.async { [weak self] in
            self?.isPersisting = false
        }
    }
}
