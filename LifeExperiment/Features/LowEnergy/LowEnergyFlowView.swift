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

    @AppStorage("app_language") private var appLanguageRaw: String = ""
    private var lang: AppLanguage { L.currentLanguage(from: appLanguageRaw) }

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
                    Button(L.actionClose(lang)) { onDismiss() }
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Step 1: Energy Check

    private var energyCheckStep: some View {
        VStack(spacing: 28) {
            VStack(spacing: 8) {
                Text(L.lowEnergyEnergyCheckTitle(lang))
                    .font(DSFont.accent(size: 22, relativeTo: .title3))
                    .multilineTextAlignment(.center)

                Text(L.lowEnergyEnergyCheckSubtitle(lang))
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
                            Text(level.localizedLabel(lang))
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
                Text(L.lowEnergyNormalExitTitle(lang))
                    .font(DSFont.accent(size: 22, relativeTo: .title3))
                    .multilineTextAlignment(.center)

                Text(L.lowEnergyNormalExitSubtitle(lang))
                    .font(DSText.subheadline)
                    .foregroundColor(.secondary)
            }

            Button {
                onDismiss()
            } label: {
                Text(L.lowEnergyContinueWithExperiment(lang))
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
                Text(L.lowEnergyActionTitle(lang))
                    .font(DSFont.accent(size: 22, relativeTo: .title3))
                    .multilineTextAlignment(.center)

                Text(L.lowEnergyActionSubtitle(lang))
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
                            Text(action.localizedLabel(lang))
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
                Text(L.lowEnergyRecoveryTitle(lang))
                    .font(DSFont.accent(size: 22, relativeTo: .title3))
                    .multilineTextAlignment(.center)

                Text(L.lowEnergyRecoverySubtitle(lang))
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
                            Text(recovery.localizedLabel(lang))
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
                Text(L.actionSkip(lang))
                    .font(DSText.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Step 4: Optional Note

    private var noteStep: some View {
        VStack(spacing: 28) {
            VStack(spacing: 8) {
                Text(L.lowEnergyNoteTitle(lang))
                    .font(DSFont.accent(size: 22, relativeTo: .title3))
                    .multilineTextAlignment(.center)

                Text(L.lowEnergyNoteSubtitle(lang))
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
                    Text(L.actionSkip(lang))
                        .font(DSText.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button {
                    advance(to: .done)
                } label: {
                    Text(L.actionDone(lang))
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
                Text(L.lowEnergyDoneTitle(lang))
                    .font(DSFont.accent(size: 22, relativeTo: .title3))
                    .multilineTextAlignment(.center)

                Text(L.lowEnergyDoneSubtitle(lang))
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
                Text(L.actionClose(lang))
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
