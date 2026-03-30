import SwiftUI

struct TitleSection: View {
    @Binding var title: String
    @FocusState.Binding var focusedField: ExperimentEditorFocusField?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Title")
                .createSectionLabelStyle()

            TextField("Experiment Title", text: $title)
                .focused($focusedField, equals: .title)
                .textFieldStyle(.plain)
                .createInputSurface()
        }
    }
}
