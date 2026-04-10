import SwiftUI

// MARK: - Experiment Row Menu (Stable trailing menu)

struct ExperimentRowMenu: View {
    enum Kind {
        case active
        case completed
    }

    let kind: Kind
    let onRename: (() -> Void)?
    let onDuplicate: () -> Void
    let onDelete: () -> Void

    init(kind: Kind, onRename: (() -> Void)? = nil, onDuplicate: @escaping () -> Void, onDelete: @escaping () -> Void) {
        self.kind = kind
        self.onRename = onRename
        self.onDuplicate = onDuplicate
        self.onDelete = onDelete
    }

    var body: some View {
        Menu {
            if kind == .active, let onRename {
                Button(action: onRename) {
                    Label("Rename", systemImage: "pencil")
                }
            }

            Button(action: onDuplicate) {
                Label("Duplicate", systemImage: "doc.on.doc")
            }

            Divider()

            Button("Delete", role: .destructive, action: onDelete)
        } label: {
            Image(systemName: "ellipsis")
                .foregroundStyle(.secondary)
                .frame(width: 44, height: 44, alignment: .center)
                .contentShape(Rectangle())
                .padding(.leading, 4)
        }
    }
}

