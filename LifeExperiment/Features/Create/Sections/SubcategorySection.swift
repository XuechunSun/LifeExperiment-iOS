import SwiftUI

struct SubcategorySection: View {
    // inputs
    let isOtherCategory: Bool
    let canPickSubcategoryFromSeed: Bool
    let hasCategorySelected: Bool

    let subcategoryDisplayText: String

    let savedCustomSubcategoriesForCurrentCategory: [String]
    let seedSubcategoryMenuItems: [SeedSubcategory]
    let savedSubcategoriesForSeedMenu: [String]

    let useCustomSubcategory: Bool
    let pickedSavedSubcategory: Bool
    let shouldShowSaveCustomSubcategoryToggle: Bool
    let willReplaceOldestSavedIfAdded: Bool

    // bindings
    @Binding var customSubcategoryText: String
    @Binding var saveCustomSubcategoryToList: Bool
    @Binding var showManageSheet: Bool

    // actions
    let enterCustomSubcategoryMode: () -> Void
    let pickSavedSubcategory: (String) -> Void
    let selectSeedSubcategoryId: (String) -> Void
    let onDismissKeyboard: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Subcategory")
                    .createSectionLabelStyle()
                Spacer()
                if !savedCustomSubcategoriesForCurrentCategory.isEmpty {
                    Button("Manage") {
                        showManageSheet = true
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .font(DSText.subheadline)
                    .foregroundStyle(.blue)
                }
            }

            VStack(alignment: .leading, spacing: 0) {
                if isOtherCategory {
                    VStack(alignment: .leading, spacing: 0) {
                        if !savedCustomSubcategoriesForCurrentCategory.isEmpty {
                            Menu {
                                ForEach(savedCustomSubcategoriesForCurrentCategory, id: \.self) { name in
                                    Button(name) {
                                        pickSavedSubcategory(name)
                                    }
                                }

                                Divider()
                                Button("Custom...") {
                                    enterCustomSubcategoryMode()
                                }
                            } label: {
                                subcategoryMenuLabel
                            }
                        }

                        if savedCustomSubcategoriesForCurrentCategory.isEmpty || useCustomSubcategory {
                            let hintText = pickedSavedSubcategory
                                ? "You can edit this subcategory below"
                                : "Please enter a custom subcategory below"
                            customInputBlock(
                                hint: hintText,
                                placeholder: "Custom Subcategory",
                                text: $customSubcategoryText
                            )
                        }

                        if shouldShowSaveCustomSubcategoryToggle {
                            saveToggleBlock
                        }
                    }
                } else if canPickSubcategoryFromSeed {
                    VStack(alignment: .leading, spacing: 0) {
                        Menu {
                            ForEach(seedSubcategoryMenuItems) { s in
                                Button(s.title) {
                                    selectSeedSubcategoryId(s.id)
                                }
                            }

                            if !savedSubcategoriesForSeedMenu.isEmpty {
                                Divider()
                                ForEach(savedSubcategoriesForSeedMenu, id: \.self) { name in
                                    Button(name) {
                                        pickSavedSubcategory(name)
                                    }
                                }
                            }

                            Divider()
                            Button("Custom...") {
                                enterCustomSubcategoryMode()
                            }
                        } label: {
                            subcategoryMenuLabel
                        }

                        if useCustomSubcategory {
                            customInputBlock(
                                hint: "Please enter a custom subcategory below",
                                placeholder: "Custom Subcategory",
                                text: $customSubcategoryText
                            )

                            if shouldShowSaveCustomSubcategoryToggle {
                                saveToggleBlock
                            }
                        }
                    }
                } else {
                    if hasCategorySelected {
                        EmptyView()
                    } else {
                        HStack {
                            Text("Select a category first")
                                .foregroundColor(.secondary)
                                .italic()
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(DSText.caption)
                                .opacity(0.0)
                        }
                    }
                }
            }
            .createInputSurface()
        }
    }

    private var subcategoryMenuLabel: some View {
        HStack {
            Text(subcategoryDisplayText)
                .foregroundColor(subcategoryDisplayText == "Select..." || subcategoryDisplayText == "Enter..." ? .secondary : .primary)
            Spacer()
            Image(systemName: "chevron.up.chevron.down")
                .font(DSText.subheadline)
                .foregroundColor(.primary)
        }
        .contentShape(Rectangle())
        .simultaneousGesture(TapGesture().onEnded {
            onDismissKeyboard()
        })
    }

    private var saveToggleBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle("Save to this category’s list", isOn: $saveCustomSubcategoryToList)
                .font(DSText.subheadline)
            Text("Up to 5 saved")
                .font(DSText.caption2)
                .foregroundColor(.secondary)
            if willReplaceOldestSavedIfAdded {
                Text("Max 5 saved — saving this will replace the oldest.")
                    .font(DSText.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 8)
    }

    private func customInputBlock(hint: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
            Text(hint)
                .font(DSText.caption)
                .foregroundColor(.secondary)
            TextField(placeholder, text: text)
                .textFieldStyle(.plain)
        }
        .padding(.top, 8)
    }
}
