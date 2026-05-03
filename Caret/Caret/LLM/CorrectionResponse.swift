import Foundation

/// Structured response the LLM returns for one correction request.
/// We deliberately ask for the original substring (`original`) rather
/// than UTF-16 offsets — LLMs are unreliable at counting indices, but
/// solid at echoing a token they just identified. Caret then searches
/// for `original` in the focused text to compute the real span.
struct CorrectionResponse: Codable, Sendable, Equatable {
    let shouldCorrect: Bool
    let original: String
    let corrected: String

    enum CodingKeys: String, CodingKey {
        case shouldCorrect = "should_correct"
        case original
        case corrected
    }
}
