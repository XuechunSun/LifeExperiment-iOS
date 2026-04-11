import SwiftUI

struct AuthOptionsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("auth_is_signed_in") private var isSignedIn: Bool = false
    @AppStorage("auth_display_name") private var authDisplayName: String = "Life Experimenter"

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Sign in (Coming soon)")
                    .font(DSText.title3)
                    .fontWeight(.semibold)

                Text("Sign in will enable backup and sync across devices.")
                    .foregroundColor(.secondary)

                Button("Continue without account") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)

                HStack {
                    Text("Sign in with Apple (Coming soon)")
                    Spacer()
                }
                .font(DSText.subheadline)
                .foregroundColor(.secondary)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .allowsHitTesting(false)

#if DEBUG
                Divider()
                    .padding(.top, 4)

                if !isSignedIn {
                    Button("Simulate signed in") {
                        isSignedIn = true
                        authDisplayName = "Life Experimenter"
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }

                Button("Simulate signed out") {
                    isSignedIn = false
                    dismiss()
                }
                .buttonStyle(.bordered)
#endif

                Spacer()
            }
            .padding(20)
            .navigationTitle("Sign in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

