import SwiftUI
import Foundation
import Combine

@MainActor
final class SubcategorySavedStore: ObservableObject {
    @AppStorage("customSubcategoriesByCategoryData") private var customSubcategoriesByCategoryData: Data = Data() {
        didSet {
            syncFromExternalIfNeeded(seedCatalog: seedCatalogSnapshot)
        }
    }
    @Published private(set) var customSubcategoriesByCategory: [String: [String]] = [:]

    private var didLoad = false
    private var isPersisting = false
    private var seedCatalogSnapshot: SeedCatalog?

    func loadIfNeeded(seedCatalog: SeedCatalog?) {
        guard !didLoad else { return }
        seedCatalogSnapshot = seedCatalog
        let decoded = decode(customSubcategoriesByCategoryData)
        let (migrated, changed) = migrateLegacyKeysIfNeeded(decoded, seedCatalog: seedCatalog)
        customSubcategoriesByCategory = migrated
        didLoad = true
        if changed {
            persist()
        }
    }

    func syncFromExternalIfNeeded(seedCatalog: SeedCatalog?) {
        guard didLoad, !isPersisting else { return }
        seedCatalogSnapshot = seedCatalog
        let decoded = decode(customSubcategoriesByCategoryData)
        let (migrated, changed) = migrateLegacyKeysIfNeeded(decoded, seedCatalog: seedCatalog)
        if migrated != customSubcategoriesByCategory {
            customSubcategoriesByCategory = migrated
        }
        if changed {
        persist()
        }
    }

    func saved(for key: String) -> [String] {
        guard !key.isEmpty else { return [] }
        if let stable = customSubcategoriesByCategory[key], !stable.isEmpty {
            return Array(stable.prefix(5))
        }
        if let legacyKey = legacyCategoryTitleKey(forStableKey: key),
           let legacy = customSubcategoriesByCategory[legacyKey], !legacy.isEmpty {
            return Array(legacy.prefix(5))
        }
        return []
    }

    func upsert(_ value: String, for key: String) {
        let normalized = trimmed(value)
        guard !key.isEmpty, !normalized.isEmpty else { return }

        var list = saved(for: key)
        let lowered = normalized.lowercased()
        list.removeAll { $0.lowercased() == lowered }
        list.insert(normalized, at: 0)
        if list.count > 5 {
            list = Array(list.prefix(5))
        }
        customSubcategoriesByCategory[key] = list
        persist()
    }

    func remove(_ value: String, for key: String) {
        guard !key.isEmpty else { return }
        var list = saved(for: key)
        list.removeAll { $0.caseInsensitiveCompare(value) == .orderedSame }
        customSubcategoriesByCategory[key] = list
        persist()
    }

    func willReplaceOldestIfAdding(_ value: String, for key: String) -> Bool {
        guard !key.isEmpty else { return false }
        let normalized = trimmed(value)
        guard !normalized.isEmpty else { return false }
        let list = saved(for: key)
        guard list.count >= 5 else { return false }
        let exists = list.contains { $0.lowercased() == normalized.lowercased() }
        return !exists
    }

    private func decode(_ data: Data) -> [String: [String]] {
        guard !data.isEmpty else { return [:] }
        return (try? JSONDecoder().decode([String: [String]].self, from: data)) ?? [:]
    }

    private func persist() {
        isPersisting = true
        customSubcategoriesByCategoryData = (try? JSONEncoder().encode(customSubcategoriesByCategory)) ?? Data()
        DispatchQueue.main.async { [weak self] in
            self?.isPersisting = false
        }
    }

    private func migrateLegacyKeysIfNeeded(_ map: [String: [String]], seedCatalog: SeedCatalog?) -> ([String: [String]], Bool) {
        guard let catalog = seedCatalog else { return (map, false) }
        let titleToStable = Dictionary(uniqueKeysWithValues: catalog.categories.map { ($0.title, "seed:\($0.id)") })
        var migrated: [String: [String]] = [:]
        var changed = false

        for (oldKey, list) in map {
            let target: String
            if oldKey == "Other" {
                target = "__other__"
            } else if oldKey == "__other__" || oldKey.hasPrefix("seed:") {
                target = oldKey
            } else if let stable = titleToStable[oldKey] {
                target = stable
            } else {
                target = oldKey
            }
            if target != oldKey {
                changed = true
            }
            migrated[target] = mergeSavedLists(migrated[target] ?? [], list)
        }

        return (migrated, changed)
    }

    private func legacyCategoryTitleKey(forStableKey key: String) -> String? {
        if key == "__other__" { return "Other" }
        guard key.hasPrefix("seed:") else { return nil }
        let seedId = String(key.dropFirst("seed:".count))
        guard let catalog = seedCatalogSnapshot else { return nil }
        return catalog.categories.first(where: { $0.id == seedId })?.title
    }

    private func mergeSavedLists(_ existing: [String], _ incoming: [String]) -> [String] {
        var out = existing
        for name in incoming {
            let value = trimmed(name)
            guard !value.isEmpty else { continue }
            out.removeAll { $0.caseInsensitiveCompare(value) == .orderedSame }
            out.append(value)
        }
        if out.count > 5 {
            out = Array(out.suffix(5))
        }
        return out
    }

    private func trimmed(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
