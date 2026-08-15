import SwiftUI

// MARK: - Today Hero Card
//
// The large card at the top of Home. It surfaces the single experiment the
// user is most likely to return to — the first entry of Continue Recording
// (active, not logged today, most recently updated).
//
// The header image is the most recent photo attached to any of that
// experiment's logs. Experiments without photos fall back to a shared
// illustration so the card keeps its visual weight either way.
//
// "Keep going" is the only navigation affordance — the card body itself is
// deliberately inert so browsing the card never pulls the user into logging.

struct TodayHeroCard: View {
    let experiment: Experiment
    let lang: AppLanguage
    let onOpen: () -> Void
    /// Opens the experiment scrolled to its History section.
    let onReadMore: () -> Void

    private static let borderColor = Color(red: 218 / 255, green: 219 / 255, blue: 224 / 255)
    private static let imageHeight: CGFloat = 180
    private static let cornerRadius: CGFloat = 12

    private var title: String {
        BuiltInTitleDisplay.localizedTitle(stored: experiment.title, lang: lang)
    }

    /// Most recent log carrying a non-empty note.
    private var latestNote: String? {
        experiment.logs
            .sorted { $0.date > $1.date }
            .lazy
            .map { $0.note.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }
    }

    /// Most recent log photo, if any log has one attached.
    private var latestPhoto: UIImage? {
        experiment.logs
            .sorted { $0.date > $1.date }
            .lazy
            .compactMap(\.photoLocalPath)
            .compactMap { LocalPhotoStore.loadImage(fromRelativePath: $0) }
            .first
    }

    private var daysSinceUpdate: Int {
        let calendar = Calendar.current
        let from = calendar.startOfDay(for: experiment.updatedAt)
        let to = calendar.startOfDay(for: Date())
        return max(0, calendar.dateComponents([.day], from: from, to: to).day ?? 0)
    }

    private var dimensionLabels: [String] {
        guard let impact = experiment.impact else { return [] }
        return ([impact.primary] + impact.additionalDimensions)
            .map { L.dimensionDisplayTitle(lang, dimension: $0) }
    }

    var body: some View {
        VStack(spacing: 10) {
            headerImage

            VStack(spacing: 10) {
                textBlock
                actionRow
            }
        }
        .padding(.bottom, 10)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
                .stroke(Self.borderColor, lineWidth: 1.2)
        )
    }

    // MARK: - Sections

    @ViewBuilder
    private var headerImage: some View {
        Group {
            if let latestPhoto {
                Image(uiImage: latestPhoto)
                    .resizable()
            } else {
                Image("HeroCardDefault")
                    .resizable()
            }
        }
        .scaledToFill()
        .frame(height: Self.imageHeight)
        .frame(maxWidth: .infinity)
        .clipped()
        .opacity(0.8)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var textBlock: some View {
        // The dimension row sits between title and note, and intentionally
        // runs wider than the surrounding copy (5pt inset vs 15pt), so the
        // padding is applied per element rather than to the stack.
        VStack(spacing: 10) {
            Text(title)
                .font(DSText.section)
                .tracking(-0.25)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 15)

            if !dimensionLabels.isEmpty {
                dimensionRow
            }

            Text(latestNote ?? L.heroNoNoteYet(lang))
                .font(DSFont.primary(size: 15, weight: .light, relativeTo: .subheadline))
                .foregroundColor(.primary.opacity(latestNote == nil ? 0.55 : 0.9))
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 15)

            if latestNote != nil {
                Button(action: onReadMore) {
                    Text(L.heroReadMore(lang))
                        .font(DSFont.primary(size: 12, weight: .light, relativeTo: .caption))
                        .underline()
                        .foregroundColor(.primary.opacity(0.75))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 15)
            }
        }
    }

    @ViewBuilder
    private var actionRow: some View {
        HStack(spacing: DSSpacing.sm) {
            Button(action: onOpen) {
                Text(L.heroKeepGoing(lang).uppercased())
                    .font(DSFont.primary(size: 12, weight: .heavy, relativeTo: .caption))
                    .tracking(1)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 35)
                    .background(
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .fill(primaryLavenderButton.opacity(0.7))
                    )
                    .shadow(color: primaryLavenderButton.opacity(0.24), radius: 16, x: 0, y: 6)
            }
            .buttonStyle(PressableCardStyle())
            .frame(maxWidth: 150)
            .accessibilityLabel("\(L.heroKeepGoing(lang)): \(title)")

            VStack(spacing: 0) {
                Text(L.heroLastUpdatedLabel(lang))
                Text(L.heroRelativeDays(lang, days: daysSinceUpdate))
            }
            .font(DSFont.primary(size: 10, relativeTo: .caption2))
            .tracking(0.5)
            .textCase(.uppercase)
            .multilineTextAlignment(.center)
            .foregroundColor(.primary.opacity(0.4))
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 15)
    }

    @ViewBuilder
    private var dimensionRow: some View {
        HStack(spacing: 5) {
            ForEach(Array(dimensionLabels.enumerated()), id: \.offset) { _, label in
                Text(label.uppercased())
                    .font(DSFont.primary(size: 8, relativeTo: .caption2))
                    .foregroundColor(primaryLavenderButton)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 10)
                    .frame(height: 17)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(.systemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(primaryLavenderButton, lineWidth: 0.8)
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 5)
    }
}
