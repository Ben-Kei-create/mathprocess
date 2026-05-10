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

/// A positive milestone shown in the Log screen. Unearned achievements keep
/// `earnedAt == nil` so the catalog can stay stable across app versions.
struct Achievement: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    var earnedAt: Date?
}

/// What user has marked for review (right answers that felt shaky,
/// recent mistakes, or 特訓 sets).
struct ReviewItem: Codable, Identifiable, Hashable {
    let id: UUID
    let problemId: String
    let reason: Reason
    let addedAt: Date
    let dueAt: Date
    let intervalDays: Int
    let reviewedCount: Int

    enum Reason: String, Codable {
        case mistake     = "間違えた問題"
        case shaky       = "あやしい問題"
        case manual      = "あとで見る"
        case scheduled   = "記憶チェック"
    }

    init(
        id: UUID,
        problemId: String,
        reason: Reason,
        addedAt: Date,
        dueAt: Date? = nil,
        intervalDays: Int = 1,
        reviewedCount: Int = 0
    ) {
        self.id = id
        self.problemId = problemId
        self.reason = reason
        self.addedAt = addedAt
        self.dueAt = dueAt ?? addedAt
        self.intervalDays = intervalDays
        self.reviewedCount = reviewedCount
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        problemId = try c.decode(String.self, forKey: .problemId)
        reason = try c.decode(Reason.self, forKey: .reason)
        addedAt = try c.decode(Date.self, forKey: .addedAt)
        dueAt = try c.decodeIfPresent(Date.self, forKey: .dueAt) ?? addedAt
        intervalDays = try c.decodeIfPresent(Int.self, forKey: .intervalDays) ?? 1
        reviewedCount = try c.decodeIfPresent(Int.self, forKey: .reviewedCount) ?? 0
    }
}
