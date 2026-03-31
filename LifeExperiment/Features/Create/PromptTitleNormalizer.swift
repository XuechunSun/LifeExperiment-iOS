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

    guard let first = title.first else { return "" }
    

    while let first = title.first, [":", "-", "–", "—"].contains(String(first)) {
        title.removeFirst()
        title = title.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    return first.uppercased() + title.dropFirst()
}
