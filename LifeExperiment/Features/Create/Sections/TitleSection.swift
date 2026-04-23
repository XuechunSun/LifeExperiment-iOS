import SwiftUI

struct TitleSection: View {
    @Binding var title: String
    @FocusState.Binding var focusedField: ExperimentEditorFocusField?
    let lang: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L.createTitleLabel(lang))
                .createSectionLabelStyle()

            TextField(L.createTitleFieldPlaceholder(lang), text: $title)
                .focused($focusedField, equals: .title)
                .textFieldStyle(.plain)
                .createInputSurface()
        }
    }
}
