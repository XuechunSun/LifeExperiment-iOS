import SwiftUI

struct DayDetailContent: View {
    let record: DayRecord
    let updateRecord: (DayRecord) -> Void

    @State private var draftNote: String
    @State private var draftMood: Mood?
    @State private var showSavedToast = false
    @FocusState private var noteFocused: Bool
    @Environment(\.dismiss) private var dismiss

    init(record: DayRecord, updateRecord: @escaping (DayRecord) -> Void) {
        self.record = record
        self.updateRecord = updateRecord
        _draftNote = State(initialValue: record.note)
        _draftMood = State(initialValue: record.mood)
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Day \(record.day)")
                .font(DSText.largeTitle)
                .fontWeight(.bold)

            Text("You completed your experiment on this day! 🎉")
                .font(DSText.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 8) {
                Text("How did you feel today? (Optional)")
                    .font(DSText.headline)

                MoodSelectorView(selectedMood: $draftMood)
            }
            .padding(.horizontal)

            VStack(alignment: .leading, spacing: 8) {
                Text("Notes:")
                    .font(DSText.headline)

                TextEditor(text: $draftNote)
                    .frame(minHeight: 150)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .focused($noteFocused)
            }
            .padding(.horizontal)

            Button(S.actionSave) {
                var updated = record
                updated.note = draftNote
                updated.mood = draftMood
                updateRecord(updated)

                // Dismiss keyboard
                noteFocused = false

                // Show toast
                showSavedToast = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showSavedToast = false
                }
            }
            .buttonStyle(.borderedProminent)

            if showSavedToast {
                Text("Saved ✓")
                    .font(DSText.caption)
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Day \(record.day)")
        .navigationBarTitleDisplayMode(.inline)
    }
}

