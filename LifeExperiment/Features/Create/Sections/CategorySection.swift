import SwiftUI

struct CategorySection: View {
    let seedCatalog: SeedCatalog?
    @Binding var isOtherCategory: Bool
    @Binding var selectedSeedCategoryId: String?
    @Binding var selectedSeedSubcategoryId: String?
    @Binding var useCustomSubcategory: Bool
    @Binding var customSubcategoryText: String
    @Binding var saveCustomSubcategoryToList: Bool
    @Binding var pickedSavedSubcategory: Bool

    let categoryDisplayText: String
    let onDismissKeyboard: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Category")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            VStack(alignment: .leading, spacing: 0) {
                Menu {
                    if let catalog = seedCatalog {
                        ForEach(catalog.categories) { c in
                            Button(c.title) {
                                isOtherCategory = false
                                selectedSeedCategoryId = c.id

                                // default to first seed subcategory for required flow
                                selectedSeedSubcategoryId = catalog.categories
                                    .first(where: { $0.id == c.id })?
                                    .subcategories
                                    .first(where: { $0.title.caseInsensitiveCompare("None") != .orderedSame })?
                                    .id
                                useCustomSubcategory = false
                                customSubcategoryText = ""
                                saveCustomSubcategoryToList = false
                                pickedSavedSubcategory = false
                            }
                        }
                    }

                    Button("Other") {
                        isOtherCategory = true
                        selectedSeedCategoryId = nil

                        // switching category clears subcategory
                        selectedSeedSubcategoryId = nil
                        useCustomSubcategory = true
                        customSubcategoryText = ""
                        saveCustomSubcategoryToList = false
                        pickedSavedSubcategory = false
                    }
                } label: {
                    HStack {
                        Text(categoryDisplayText)
                            .foregroundColor(categoryDisplayText == "Select..." ? .secondary : .primary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                    .simultaneousGesture(TapGesture().onEnded {
                        onDismissKeyboard()
                    })
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}
