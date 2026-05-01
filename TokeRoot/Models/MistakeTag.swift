import Foundation

/// A "stuck point" — the specific place a student tends to lose their footing.
/// Each wrong answer in a step is mapped to a MistakeTag so we can suggest a
/// targeted 「ここだけ特訓」 set instead of generic re-practice.
struct MistakeTag: Codable, Identifiable, Hashable {
    let id: String              // e.g. "isolate-2x-to-x"
    let label: String           // e.g. "2xをxにする"
    let kindMessage: String     // shown after a wrong answer, gentle
    let practiceSetId: String   // which recovery set to recommend
}
