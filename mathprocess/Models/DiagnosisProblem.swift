import Foundation

/// A diagnosis-test problem. Lighter than `Problem` — used only by the
/// initial route placement test, not for daily learning.
struct DiagnosisProblem: Codable, Identifiable, Hashable {
    let id: String
    let unitId: String
    let equation: String
    let questionPrompt: String       // e.g. "次のxの値は？"
    let choices: [Choice]
    let mistakeTagIdIfWrong: String  // tells the route engine what to recommend
    let order: Int

    struct Choice: Codable, Identifiable, Hashable {
        let id: String
        let label: String
        let isCorrect: Bool
    }
}

/// Result summary after the diagnosis test finishes.
struct DiagnosisResult: Codable, Hashable {
    let unitId: String
    let strengths: [String]              // 「〜はできています」
    let recommendedPracticeSetId: String // where to start
    let kindMessage: String              // overall tone, focuses on strengths
}
