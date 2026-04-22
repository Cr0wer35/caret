import Foundation

/// Structured response the LLM returns for one correction request.
/// Offsets are UTF-16 code-unit positions in the submitted text.
struct CorrectionResponse: Codable, Sendable, Equatable {
    let shouldCorrect: Bool
    let spanStart: Int
    let spanEnd: Int
    let corrected: String

    enum CodingKeys: String, CodingKey {
        case shouldCorrect = "should_correct"
        case spanStart = "span_start"
        case spanEnd = "span_end"
        case corrected
    }
}
