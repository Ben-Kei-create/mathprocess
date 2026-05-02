import Foundation

/// One step within a problem. A step asks 「次に何をする？」 and offers
/// 2-4 choices, exactly one of which is correct. Wrong choices carry a
/// `mistakeTagId` so the app can route the user to focused practice.
struct ProblemStep: Codable, Identifiable, Hashable {
    let id: String
    let prompt: String                // e.g. "まず何をする？"
    let equationBefore: String        // shown in the card before this step
    let choices: [Choice]
    let explanationCaption: String    // shown when the step advances
    let equationAfter: String         // card after this step
    let highlight: String?            // substring to highlight (e.g. "-3")

    struct Choice: Codable, Identifiable, Hashable {
        let id: String
        let label: String
        let isCorrect: Bool
        let mistakeTagId: String?     // nil if correct
    }

    var correctChoice: Choice {
        choices.first(where: { $0.isCorrect }) ?? choices[0]
    }
}

/// The three solving modes the unit progresses through. MVP only ships
/// `.nextMove` but the data structure already accommodates the others.
enum SolveMode: String, Codable, CaseIterable {
    case nextMove = "次の一手モード"
    case fillIn   = "穴埋めモード"
    case selfMade = "自力モード"
}

struct Problem: Codable, Identifiable, Hashable {
    let id: String
    let unitId: String
    let title: String                 // short label, optional
    let equation: String              // headline equation: "2x + 3 = 11"
    let mode: SolveMode
    let difficulty: Int               // 1...5
    let steps: [ProblemStep]
    let finalAnswer: String           // "x = 4"
    let hint: String                  // single calm hint
    let tags: [String]                // free-form tags ("移項", "係数")
}

/// A small targeted set used by 「ここだけ特訓」 and the recovery route.
struct PracticeSet: Codable, Identifiable, Hashable {
    let id: String
    let title: String                 // "2xをxにする練習"
    let mistakeTagId: String
    let problemIds: [String]
}
