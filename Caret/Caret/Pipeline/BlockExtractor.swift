import Foundation

/// A self-contained slice of the focused field's text, plus the
/// UTF-16 range that maps it back into the original.
struct TextBlock: Sendable, Equatable {
    let text: String
    let range: NSRange
}

/// Pure helper that returns the paragraph (`\n\n`-delimited) containing
/// the cursor. Returns `nil` when the surrounding paragraph exceeds
/// `maxWords`, in which case the trigger pipeline skips the request
/// rather than send a huge prompt.
nonisolated enum BlockExtractor {
    static func extract(
        from text: String,
        cursor: Int,
        maxWords: Int = 200
    ) -> TextBlock? {
        let nsText = text as NSString
        let total = nsText.length
        guard total > 0 else { return nil }

        let clamped = max(0, min(cursor, total))
        let start = blockStart(in: nsText, before: clamped)
        let end = blockEnd(in: nsText, from: clamped)
        guard end > start else { return nil }

        let range = NSRange(location: start, length: end - start)
        let block = nsText.substring(with: range)

        let wordCount = block.split(whereSeparator: \.isWhitespace).count
        guard wordCount <= maxWords else { return nil }

        return TextBlock(text: block, range: range)
    }

    /// Walks backward from `offset` and returns the index right after
    /// the previous `\n\n`, or `0` if none.
    private static func blockStart(in text: NSString, before offset: Int) -> Int {
        var consecutiveNewlines = 0
        var index = offset - 1
        while index >= 0 {
            let char = text.character(at: index)
            if char == 0x0A {
                consecutiveNewlines += 1
                if consecutiveNewlines >= 2 {
                    return index + 2
                }
            } else {
                consecutiveNewlines = 0
            }
            index -= 1
        }
        return 0
    }

    /// Walks forward from `offset` and returns the index of the first
    /// of the next `\n\n` (exclusive), or end-of-text if none.
    private static func blockEnd(in text: NSString, from offset: Int) -> Int {
        let total = text.length
        var consecutiveNewlines = 0
        var index = offset
        while index < total {
            let char = text.character(at: index)
            if char == 0x0A {
                consecutiveNewlines += 1
                if consecutiveNewlines >= 2 {
                    return index - 1
                }
            } else {
                consecutiveNewlines = 0
            }
            index += 1
        }
        return total
    }
}
