import Foundation

struct CleanupResult: Sendable {
    let original: String
    let cleaned: String
    let changes: [String]
}

@MainActor
final class TextCleanup {

    // MARK: - Filler words & phrases

    /// Multi-word filler phrases (checked first, before single-word fillers)
    private let fillerPhrases: [String] = [
        "you know", "i mean", "sort of", "kind of",
    ]

    /// Single-word fillers removed unconditionally
    private let fillerWords: Set<String> = [
        "um", "uh", "umm", "uhh", "er", "ah", "hmm",
        "basically", "actually", "literally",
    ]

    /// Words that are fillers only when surrounded by other words
    /// (e.g. "like" as in "I was like going" but not "I like pizza")
    private let contextFillers: Set<String> = ["like"]

    // MARK: - Whisper artifacts

    private let artifactPatterns: [String] = [
        "\\[BLANK_AUDIO\\]",
        "\\(blank audio\\)",
        "\\[silence\\]",
        "\\(music\\)",
        "\\[music\\]",
        "\\[inaudible\\]",
    ]

    // MARK: - Public API

    func cleanup(_ text: String) -> CleanupResult {
        let original = text
        var current = text
        var changes: [String] = []

        // 1. Remove whisper artifacts
        let artifactResult = removeArtifacts(current)
        current = artifactResult.text
        changes.append(contentsOf: artifactResult.changes)

        // 2. Remove filler phrases (multi-word, before single-word)
        let phraseResult = removeFillerPhrases(current)
        current = phraseResult.text
        changes.append(contentsOf: phraseResult.changes)

        // 3. Remove filler words (single-word)
        let wordResult = removeFillerWords(current)
        current = wordResult.text
        changes.append(contentsOf: wordResult.changes)

        // 4. Clean up multiple spaces
        let spaceBefore = current
        current = collapseSpaces(current)
        if current != spaceBefore {
            changes.append("Cleaned up extra spaces")
        }

        // 5. Fix spacing before punctuation (remove space before . , ! ? : ;)
        let punctBefore = current
        current = fixPunctuationSpacing(current)
        if current != punctBefore {
            changes.append("Fixed punctuation spacing")
        }

        // 6. Capitalize first letter of each sentence
        let capBefore = current
        current = capitalizeSentences(current)
        if current != capBefore {
            changes.append("Capitalized sentence starts")
        }

        // 7. Ensure ending period
        let trimmed = current.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            let lastChar = trimmed.last!
            if !lastChar.isPunctuation {
                current = trimmed + "."
                changes.append("Added ending period")
            } else {
                current = trimmed
            }
        }

        // 8. Final trim
        current = current.trimmingCharacters(in: .whitespacesAndNewlines)

        return CleanupResult(original: original, cleaned: current, changes: changes)
    }

    // MARK: - Private helpers

    private struct StepResult {
        let text: String
        let changes: [String]
    }

    private func removeArtifacts(_ text: String) -> StepResult {
        var current = text
        var changes: [String] = []

        for pattern in artifactPatterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
                continue
            }
            let range = NSRange(current.startIndex..., in: current)
            let count = regex.numberOfMatches(in: current, range: range)
            if count > 0 {
                current = regex.stringByReplacingMatches(in: current, range: range, withTemplate: "")
                // Extract readable name from pattern
                let name = pattern
                    .replacingOccurrences(of: "\\[", with: "[")
                    .replacingOccurrences(of: "\\]", with: "]")
                    .replacingOccurrences(of: "\\(", with: "(")
                    .replacingOccurrences(of: "\\)", with: ")")
                changes.append("Removed \(count)x '\(name)'")
            }
        }

        return StepResult(text: current, changes: changes)
    }

    private func removeFillerPhrases(_ text: String) -> StepResult {
        var current = text
        var changes: [String] = []

        for phrase in fillerPhrases {
            let escaped = NSRegularExpression.escapedPattern(for: phrase)
            // Match the phrase as whole words, case-insensitive
            let pattern = "\\b\(escaped)\\b"
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
                continue
            }
            let range = NSRange(current.startIndex..., in: current)
            let count = regex.numberOfMatches(in: current, range: range)
            if count > 0 {
                current = regex.stringByReplacingMatches(in: current, range: range, withTemplate: "")
                changes.append("Removed \(count)x '\(phrase)'")
            }
        }

        return StepResult(text: current, changes: changes)
    }

    private func removeFillerWords(_ text: String) -> StepResult {
        var current = text
        var changes: [String] = []
        var removals: [String: Int] = [:]

        // Remove unconditional fillers
        for word in fillerWords {
            let escaped = NSRegularExpression.escapedPattern(for: word)
            let pattern = "\\b\(escaped)\\b"
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
                continue
            }
            let range = NSRange(current.startIndex..., in: current)
            let count = regex.numberOfMatches(in: current, range: range)
            if count > 0 {
                current = regex.stringByReplacingMatches(in: current, range: range, withTemplate: "")
                removals[word] = count
            }
        }

        // Remove context-sensitive fillers ("like" between words, with comma patterns)
        for word in contextFillers {
            // Match "like" when preceded by a word and followed by a word (filler usage)
            // Also matches ", like," patterns
            let pattern = "(?<=\\w)\\s*,?\\s*\\b\(word)\\b\\s*,?\\s*(?=\\w)"
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
                continue
            }
            let range = NSRange(current.startIndex..., in: current)
            let count = regex.numberOfMatches(in: current, range: range)
            if count > 0 {
                current = regex.stringByReplacingMatches(in: current, range: range, withTemplate: " ")
                removals[word] = count
            }
        }

        for (word, count) in removals.sorted(by: { $0.key < $1.key }) {
            changes.append("Removed \(count)x '\(word)'")
        }

        return StepResult(text: current, changes: changes)
    }

    private func collapseSpaces(_ text: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: "[ \\t]+", options: []) else {
            return text
        }
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(in: text, range: range, withTemplate: " ")
    }

    private func fixPunctuationSpacing(_ text: String) -> String {
        // Remove spaces before punctuation marks
        guard let regex = try? NSRegularExpression(pattern: "\\s+([.,!?;:])", options: []) else {
            return text
        }
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(in: text, range: range, withTemplate: "$1")
    }

    private func capitalizeSentences(_ text: String) -> String {
        guard !text.isEmpty else { return text }

        var result = text

        // Capitalize first character of the entire string
        if let firstLetterRange = result.rangeOfCharacter(from: .letters) {
            let upper = String(result[firstLetterRange]).uppercased()
            result.replaceSubrange(firstLetterRange, with: upper)
        }

        // Capitalize first letter after sentence-ending punctuation
        guard let regex = try? NSRegularExpression(pattern: "([.!?])\\s+(\\w)", options: []) else {
            return result
        }
        let nsRange = NSRange(result.startIndex..., in: result)
        let matches = regex.matches(in: result, range: nsRange)

        // Process matches in reverse to maintain index stability
        for match in matches.reversed() {
            guard match.numberOfRanges == 3,
                  let letterRange = Range(match.range(at: 2), in: result) else {
                continue
            }
            let upper = String(result[letterRange]).uppercased()
            result.replaceSubrange(letterRange, with: upper)
        }

        return result
    }
}
