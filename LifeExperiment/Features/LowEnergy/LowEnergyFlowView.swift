import SwiftUI

struct LowEnergyFlowView: View {
    let onComplete: (LowEnergyLog) -> Void
    let onDismiss: () -> Void

    private enum Step: Int, CaseIterable {
        case energyCheck = 0
        case normalExit = 1
        case action = 2
        case recovery = 3
        case note = 4
        case done = 5
    }

    @State private var step: Step = .energyCheck
    @State private var isTransitioning = false
    @State private var selectedEnergy: EnergyLevel?
    @State private var selectedAction: MinimalAction?
    @State private var selectedRecovery: RecoveryType?
    @State private var noteText: String = ""

    private func advance(to next: Step) {
        guard !isTransitioning else { return }
        isTransitioning = true
        withAnimation {
            step = next
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isTransitioning = false
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()

                Group {
                    switch step {
                    case .energyCheck: energyCheckStep
                    case .normalExit: normalExitStep
                    case .action: actionStep
                    case .recovery: recoveryStep
                    case .note: noteStep
                    case .done: doneStep
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .animation(.easeInOut(duration: 0.25), value: step)

                Spacer()
            }
            .padding(.horizontal, 24)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { onDismiss() }
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Step 1: Energy Check

    private var energyCheckStep: some View {
        VStack(spacing: 28) {
            VStack(spacing: 8) {
                Text("How are you feeling right now?")
                    .font(DSFont.accent(size: 22, relativeTo: .title3))
                    .multilineTextAlignment(.center)

                Text("No right answer here.")
                    .font(DSText.subheadline)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 12) {
                ForEach(EnergyLevel.allCases, id: \.self) { level in
                    Button {
                        selectedEnergy = level
                        if level == .normal {
                            advance(to: .normalExit)
                        } else {
                            advance(to: .action)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Text(level.emoji)
                                .font(.title2)
                            Text(level.label)
                                .font(DSText.body)
                                .fontWeight(.medium)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(14)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Step 1b: Normal Exit (RF#2)

    private var normalExitStep: some View {
        VStack(spacing: 28) {
            VStack(spacing: 8) {
                Text("Sounds like you're doing okay today")
                    .font(DSFont.accent(size: 22, relativeTo: .title3))
                    .multilineTextAlignment(.center)

                Text("That's a good thing.")
                    .font(DSText.subheadline)
                    .foregroundColor(.secondary)
            }

            Button {
                onDismiss()
            } label: {
                Text("Continue with an experiment")
                    .font(DSText.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(primaryLavenderButton)
                    .cornerRadius(12)
            }
        }
    }

    // MARK: - Step 2: Minimal Action

    private var actionStep: some View {
        VStack(spacing: 28) {
            VStack(spacing: 8) {
                Text("Pick one small thing")
                    .font(DSFont.accent(size: 22, relativeTo: .title3))
                    .multilineTextAlignment(.center)

                Text("Just enough to say you did something.")
                    .font(DSText.subheadline)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 12) {
                ForEach(MinimalAction.allCases, id: \.self) { action in
                    Button {
                        selectedAction = action
                        advance(to: .recovery)
                    } label: {
                        HStack(spacing: 12) {
                            Text(action.emoji)
                                .font(.title2)
                            Text(action.label)
                                .font(DSText.body)
                                .fontWeight(.medium)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(14)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Step 3: Optional Recovery

    private var recoveryStep: some View {
        VStack(spacing: 28) {
            VStack(spacing: 8) {
                Text("How will you recharge?")
                    .font(DSFont.accent(size: 22, relativeTo: .title3))
                    .multilineTextAlignment(.center)

                Text("Optional. Skip if nothing fits.")
                    .font(DSText.subheadline)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 12) {
                ForEach(RecoveryType.allCases, id: \.self) { recovery in
                    Button {
                        selectedRecovery = recovery
                        advance(to: .note)
                    } label: {
                        HStack(spacing: 12) {
                            Text(recovery.emoji)
                                .font(.title2)
                            Text(recovery.label)
                                .font(DSText.body)
                                .fontWeight(.medium)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(14)
                    }
                    .buttonStyle(.plain)
                }
            }

            Button {
                advance(to: .note)
            } label: {
                Text("Skip")
                    .font(DSText.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Step 4: Optional Note

    private var noteStep: some View {
        VStack(spacing: 28) {
            VStack(spacing: 8) {
                Text("Anything on your mind?")
                    .font(DSFont.accent(size: 22, relativeTo: .title3))
                    .multilineTextAlignment(.center)

                Text("A word, a thought. Or nothing at all.")
                    .font(DSText.subheadline)
                    .foregroundColor(.secondary)
            }

            TextField("", text: $noteText, axis: .vertical)
                .font(DSText.body)
                .lineLimit(3...5)
                .padding(14)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(14)

            HStack(spacing: 16) {
                Button {
                    advance(to: .done)
                } label: {
                    Text("Skip")
                        .font(DSText.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button {
                    advance(to: .done)
                } label: {
                    Text("Done")
                        .font(DSText.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 12)
                        .background(primaryLavenderButton)
                        .cornerRadius(12)
                }
            }
        }
    }

    // MARK: - Step 5: Done

    private var doneStep: some View {
        VStack(spacing: 28) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 40))
                .foregroundColor(.green.opacity(0.7))

            VStack(spacing: 8) {
                Text("That's enough for today")
                    .font(DSFont.accent(size: 22, relativeTo: .title3))
                    .multilineTextAlignment(.center)

                Text("You showed up. That counts.")
                    .font(DSText.subheadline)
                    .foregroundColor(.secondary)
            }

            Button {
                guard let energy = selectedEnergy, let action = selectedAction else { return }
                let trimmedNote = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
                let log = LowEnergyLog(
                    energyLevel: energy,
                    actionType: action,
                    recoveryType: selectedRecovery,
                    note: trimmedNote.isEmpty ? nil : trimmedNote
                )
                onComplete(log)
            } label: {
                Text("Close")
                    .font(DSText.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(primaryLavenderButton)
                    .cornerRadius(12)
            }
        }
    }
}
