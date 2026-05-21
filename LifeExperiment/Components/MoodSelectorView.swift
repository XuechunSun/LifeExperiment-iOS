import SwiftUI

private let moodSelectorLavender = Color(red: 0.69, green: 0.68, blue: 0.93)

private extension Mood {
    func shortLabel(_ lang: AppLanguage) -> String {
        switch self {
        case .veryBad:  return lang == .english ? "Low"    : "低落"
        case .bad:      return lang == .english ? "Uneasy" : "不安"
        case .neutral:  return lang == .english ? "Okay"   : "一般"
        case .good:     return lang == .english ? "Good"   : "还好"
        case .veryGood: return lang == .english ? "Bright" : "开心"
        }
    }
}

struct MoodSelectorView: View {
    @Binding var selectedMood: Mood?
    @AppStorage("app_language") private var appLanguageRaw: String = ""
    private var lang: AppLanguage { L.currentLanguage(from: appLanguageRaw) }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Mood.allCases) { mood in
                let isSelected = selectedMood == mood
                Button {
                    Haptics.selection()
                    if isSelected {
                        selectedMood = nil
                    } else {
                        selectedMood = mood
                    }
                } label: {
                    VStack(spacing: 5) {
                        Text(mood.emoji)
                            .font(.title2)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(isSelected ? moodSelectorLavender.opacity(0.16) : Color.clear)
                            )
                            .overlay(
                                Circle()
                                    .stroke(
                                        isSelected ? moodSelectorLavender.opacity(0.45) : Color.gray.opacity(0.3),
                                        lineWidth: 2
                                    )
                            )

                        Text(mood.shortLabel(lang))
                            .font(.caption2)
                            .foregroundColor(isSelected ? .primary : .secondary)
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
    }
}
