import Foundation

/// Structured response the LLM returns for one correction request.
/// Caret sends a single self-contained block of text and gets back
/// the same block fully corrected. The replacement is applied 1:1
/// over the source range — no offset arithmetic on our side.
struct CorrectionResponse: Codable, Sendable, Equatable {
    let shouldCorrect: Bool
    let corrected: String

    enum CodingKeys: String, CodingKey {
        case shouldCorrect = "should_correct"
        case corrected
    }
}
