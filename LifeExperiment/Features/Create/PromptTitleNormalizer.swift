import Foundation

func normalizedTitle(from prompt: String) -> String {
    var title = prompt.trimmingCharacters(in: .whitespacesAndNewlines)

    while let last = title.last, [".", "!", "?"].contains(String(last)) {
        title.removeLast()
    }

    let conversationalStarters = [
        "Try to",
        "Try",
        "Notice",
        "Write down",
        "Write",
        "Identify",
        "Think about",
        "Ask yourself",
        "Start",
        "Take time to"
    ]

    for starter in conversationalStarters {
        if title.range(of: starter, options: [.caseInsensitive, .anchored]) != nil {
            title.removeFirst(starter.count)
            title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            break
        }
    }

    while let leadingChar = title.first, [":", "-", "–", "—"].contains(String(leadingChar)) {
        title.removeFirst()
        title = title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    guard let first = title.first else { return "" }
    return first.uppercased() + title.dropFirst()
}
