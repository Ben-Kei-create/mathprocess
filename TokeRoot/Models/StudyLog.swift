import Foundation

/// A single solving event. Aggregated for daily/weekly views.
struct StudyEvent: Codable, Identifiable, Hashable {
    let id: UUID
    let date: Date
    let unitId: String
    let problemId: String
    let durationSeconds: Int
    let outcome: Outcome
    let mistakeTagIds: [String]   // empty if cleared first try

    enum Outcome: String, Codable {
        case solved        // cleared (first try or after retry)
        case partial       // gave up part-way
        case practice      // 特訓 problem cleared
    }
}

/// Daily summary for the calendar habit indicator.
struct DailyMark: Codable, Hashable {
    let day: Date            // start-of-day
    let symbol: Symbol
    let totalSeconds: Int

    enum Symbol: String, Codable {
        case exceeded   = "◎"   // exceeded daily goal
        case reached    = "✓"   // reached goal
        case some       = "○"   // studied a little
        case none       = "-"   // no study (never red, never shamed)
    }
}

/// What user has marked for review (right answers that felt shaky,
/// recent mistakes, or 特訓 sets).
struct ReviewItem: Codable, Identifiable, Hashable {
    let id: UUID
    let problemId: String
    let reason: Reason
    let addedAt: Date

    enum Reason: String, Codable {
        case mistake     = "間違えた問題"
        case shaky       = "あやしい問題"
        case manual      = "あとで見る"
    }
}
