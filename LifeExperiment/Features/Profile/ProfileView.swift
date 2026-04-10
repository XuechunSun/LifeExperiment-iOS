//
//  ProfileView.swift
//  LifeExperiment
//
//  Created on 1/27/26.
//

import SwiftUI

struct ProfileView: View {
    let loadExperiments: () -> [Experiment]
    let onResetAllData: () -> Void

    // Placeholder-only until cloud sync is implemented.
    @AppStorage("pref_cloud_sync_enabled") private var cloudSyncEnabled: Bool = false
    @AppStorage("auth_is_signed_in") private var isSignedIn: Bool = false
    @AppStorage("auth_display_name") private var authDisplayName: String = "Life Experimenter"

    @State private var showSignInSheet = false
    @State private var showSignOutConfirm = false
    @State private var showResetAllDataConfirm = false

    private var preferences = AppPreferences()

    init(
        loadExperiments: @escaping () -> [Experiment],
        onResetAllData: @escaping () -> Void = {}
    ) {
        self.loadExperiments = loadExperiments
        self.onResetAllData = onResetAllData
    }

    private var experiments: [Experiment] {
        loadExperiments()
    }

    private var shownUpCount: Int {
        experiments.reduce(0) { partial, experiment in
            partial + experiment.logs.filter { log in
                let trimmedNote = log.note.trimmingCharacters(in: .whitespacesAndNewlines)
                return !trimmedNote.isEmpty || log.mood != nil
            }.count
        }
    }

    private var headerSubtitle: String {
        shownUpCount > 0 ? "You've shown up \(shownUpCount) times" : "Still exploring"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(.tint)

                    VStack(spacing: 6) {
                        Text(authDisplayName)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)

                        Text(headerSubtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        Text(isSignedIn ? "Signed in" : "Using this device only")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
                .lightCardStyle(
                    cornerRadius: 16,
                    fillColor: Color(.systemBackground),
                    fillOpacity: 1.0,
                    borderOpacity: 0.04,
                    shadowOpacity: 0.02,
                    shadowRadius: 6,
                    shadowYOffset: 2,
                    contentPadding: preferences.uiStyle.cardPadding
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text("Your experience")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .top, spacing: DSSpacing.md) {
                            VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                                Text("UI Style")
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                Text("Choose how the app feels")
                                    .lifeCaption()
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer()

                            Picker("UI Style", selection: preferences.uiStyleBinding) {
                                ForEach(UIStyle.allCases) { style in
                                    Text(style.title).tag(style)
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                        }
                        .padding(.vertical, 12)

                        Divider()

                        HStack(alignment: .top, spacing: DSSpacing.md) {
                            VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                                Text("Image logging")
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                Text("Add photos to your daily logs")
                                    .lifeCaption()
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer()

                            Toggle("", isOn: preferences.imageLoggingEnabledBinding)
                                .labelsHidden()
                        }
                        .padding(.vertical, 12)

                        Divider()

                        NavigationLink(value: Route.completedMore) {
                            HStack(alignment: .top, spacing: DSSpacing.md) {
                                VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                                    Text("Completed Experiments")
                                        .font(.subheadline)
                                        .fontWeight(.medium)

                                    Text("Browse experiments you’ve already finished")
                                        .lifeCaption()
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 2)
                            }
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                    }
                    .lightCardStyle(
                        cornerRadius: preferences.uiStyle.cardCornerRadius,
                        fillColor: Color(.systemBackground),
                        fillOpacity: 1.0,
                        borderOpacity: 0.04,
                        shadowOpacity: 0.02,
                        shadowRadius: 6,
                        shadowYOffset: 2,
                        contentPadding: preferences.uiStyle.cardPadding
                    )
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Data & System")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .top, spacing: DSSpacing.md) {
                            VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                                Text("Cloud sync")
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                Text("Coming soon")
                                    .lifeCaption()

                                Text("Your data is currently stored on this device")
                                    .lifeCaption()
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer() 
                        }
                        .frame(maxWidth: .infinity, alignment: .leading) 
                        .padding(.vertical, 12) 
                    }
                    .frame(maxWidth: .infinity)
                    .lightCardStyle(
                        cornerRadius: preferences.uiStyle.cardCornerRadius,
                        fillColor: Color(.systemBackground),
                        fillOpacity: 1.0,
                        borderOpacity: 0.04,
                        shadowOpacity: 0.02,
                        shadowRadius: 6,
                        shadowYOffset: 2,
                        contentPadding: preferences.uiStyle.cardPadding
                    )
                }

                if isSignedIn {
                    Button {
                        showSignOutConfirm = true
                    } label: {
                        Text("Sign out")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .padding(.top, 4)
                } else {
                    Button {
                        showSignInSheet = true
                    } label: {
                        Text("Sign in")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(primaryLavenderButton)
                    .padding(.top, 4)
                }

                Text("Built for curiosity")
                    .lifeCaption()
                    .frame(maxWidth: .infinity)

#if DEBUG
                VStack(alignment: .leading, spacing: 8) {
                    Text("Debug")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 0) {
                        Button(role: .destructive) {
                            showResetAllDataConfirm = true
                        } label: {
                            Text("Reset All Data")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 12)
                    }
                    .lightCardStyle(
                        cornerRadius: preferences.uiStyle.cardCornerRadius,
                        fillColor: Color(.systemBackground),
                        fillOpacity: 1.0,
                        borderOpacity: 0.04,
                        shadowOpacity: 0.02,
                        shadowRadius: 6,
                        shadowYOffset: 2,
                        contentPadding: preferences.uiStyle.cardPadding
                    )
                }
#endif
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: Binding(
            get: { showSignInSheet && !isSignedIn },
            set: { showSignInSheet = $0 }
        )) {
            AuthOptionsSheet()
        }
        .alert("Sign out?", isPresented: $showSignOutConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Sign out", role: .destructive) {
                isSignedIn = false
            }
        } message: {
            Text("You can continue using the app locally.")
        }
        .alert("Reset all app data?", isPresented: $showResetAllDataConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                onResetAllData()
            }
        } message: {
            Text("This will permanently delete all experiments, logs, saved custom subcategories, and locally stored images on this device.")
        }
    }
}
