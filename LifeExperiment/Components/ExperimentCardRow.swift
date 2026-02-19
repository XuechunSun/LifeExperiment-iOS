import SwiftUI

// MARK: - Reusable Card Component

struct ExperimentCardRow: View {
    let title: String
    let subtitle: String
    let leadingIcon: String?

    init(title: String, subtitle: String, leadingIcon: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.leadingIcon = leadingIcon
    }

    // Convenience initializer for Experiment
    init(experiment: Experiment) {
        self.title = experiment.title

        // Format subtitle based on experiment status
        if experiment.status == .completed, let completedAt = experiment.completedAt {
            self.subtitle = "Completed \(completedAt.formatted(date: .abbreviated, time: .omitted))"
        } else {
            self.subtitle = "Last updated \(experiment.updatedAt.formatted(date: .abbreviated, time: .omitted))"
        }

        self.leadingIcon = nil
    }

    var body: some View {
        HStack(spacing: 12) {
            if let icon = leadingIcon {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .contentShape(Rectangle())
    }
}

