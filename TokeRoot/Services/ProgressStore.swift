import Foundation

/// Mutable, persisted user state. Saved as a single JSON blob in
/// `UserDefaults` for MVP simplicity — small surface, no migrations
/// to worry about for the prototype.
@Observable
final class ProgressStore {
    static let shared = ProgressStore()

    var profile: UserProfile = .empty
    var events: [StudyEvent] = []
    var reviewItems: [ReviewItem] = []
    var achievements: [Achievement] = ProgressStore.defaultAchievements
    var lastProblemId: String? = nil
    var lastUnitId: String? = nil
    var memoText: String = ""
    var memoDrawingData: Data = Data()
    var stuckCounts: [String: Int] = [:]   // mistakeTagId -> count

    private let key = "tokeroot.progress.v1"

    private init() { load() }

    // MARK: persistence

    private struct Snapshot: Codable {
        var profile: UserProfile
        var events: [StudyEvent]
        var reviewItems: [ReviewItem]
        var achievements: [Achievement]
        var lastProblemId: String?
        var lastUnitId: String?
        var memoText: String
        var memoDrawingData: Data
        var stuckCounts: [String: Int]

        init(profile: UserProfile,
             events: [StudyEvent],
             reviewItems: [ReviewItem],
             achievements: [Achievement],
             lastProblemId: String?,
             lastUnitId: String?,
             memoText: String,
             memoDrawingData: Data,
             stuckCounts: [String: Int]) {
            self.profile = profile
            self.events = events
            self.reviewItems = reviewItems
            self.achievements = achievements
            self.lastProblemId = lastProblemId
            self.lastUnitId = lastUnitId
            self.memoText = memoText
            self.memoDrawingData = memoDrawingData
            self.stuckCounts = stuckCounts
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            profile = try c.decode(UserProfile.self, forKey: .profile)
            events = try c.decode([StudyEvent].self, forKey: .events)
            reviewItems = try c.decode([ReviewItem].self, forKey: .reviewItems)
            achievements = try c.decodeIfPresent([Achievement].self, forKey: .achievements)
                ?? ProgressStore.defaultAchievements
            lastProblemId = try c.decodeIfPresent(String.self, forKey: .lastProblemId)
            lastUnitId = try c.decodeIfPresent(String.self, forKey: .lastUnitId)
            memoText = try c.decode(String.self, forKey: .memoText)
            memoDrawingData = try c.decodeIfPresent(Data.self, forKey: .memoDrawingData) ?? Data()
            stuckCounts = try c.decode([String: Int].self, forKey: .stuckCounts)
        }
    }

    func save() {
        let snap = Snapshot(
            profile: profile,
            events: events,
            reviewItems: reviewItems,
            achievements: achievements,
            lastProblemId: lastProblemId,
            lastUnitId: lastUnitId,
            memoText: memoText,
            memoDrawingData: memoDrawingData,
            stuckCounts: stuckCounts
        )
        if let data = try? JSONEncoder().encode(snap) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let snap = try? JSONDecoder().decode(Snapshot.self, from: data) else {
            return
        }
        self.profile = snap.profile
        self.events = snap.events
        self.reviewItems = snap.reviewItems
        self.achievements = Self.mergedAchievements(from: snap.achievements)
        self.lastProblemId = snap.lastProblemId
        self.lastUnitId = snap.lastUnitId
        self.memoText = snap.memoText
        self.memoDrawingData = snap.memoDrawingData
        self.stuckCounts = snap.stuckCounts
        checkAchievements()
    }

    // MARK: mutations

    func recordEvent(_ e: StudyEvent) {
        events.append(e)
        for tag in e.mistakeTagIds {
            stuckCounts[tag, default: 0] += 1
        }
        lastProblemId = e.problemId
        lastUnitId = e.unitId
        checkAchievements()
        save()
    }

    func addReview(_ item: ReviewItem) {
        if !reviewItems.contains(where: { $0.problemId == item.problemId && $0.reason == item.reason }) {
            reviewItems.append(item)
            save()
        }
    }

    func removeReview(_ id: UUID) {
        reviewItems.removeAll { $0.id == id }
        save()
    }

    /// Reset the saved snapshot — used by Settings 「最初からやり直す」.
    func resetAll() {
        profile = .empty
        events = []
        reviewItems = []
        achievements = Self.defaultAchievements
        lastProblemId = nil
        lastUnitId = nil
        memoText = ""
        memoDrawingData = Data()
        stuckCounts = [:]
        save()
    }

    func checkAchievements(now: Date = .now, data: DataService = .shared) {
        if !events.isEmpty {
            unlockAchievement("first-solve", at: now)
        }

        let longestStreak = longestStreakDays()
        if longestStreak >= 3 {
            unlockAchievement("streak-3", at: now)
        }
        if longestStreak >= 7 {
            unlockAchievement("streak-7", at: now)
        }
        if longestStreak >= 30 {
            unlockAchievement("streak-30", at: now)
        }

        if events.contains(where: { event in
            data.problem(id: event.problemId)?.tags.contains("特訓") == true
        }) {
            unlockAchievement("first-practice", at: now)
        }

        let solvedProblemIds = Set(events.map(\.problemId))
        if data.units.contains(where: { unit in
            let unitProblemIds = data.problems(in: unit.id).map(\.id)
            return !unitProblemIds.isEmpty && unitProblemIds.allSatisfy { solvedProblemIds.contains($0) }
        }) {
            unlockAchievement("unit-complete", at: now)
        }

        if profile.hasCompletedDiagnosis {
            unlockAchievement("diagnosis-complete", at: now)
        }
    }

    // MARK: derived

    func todaySeconds(now: Date = .now) -> Int {
        let cal = Calendar.current
        return events
            .filter { cal.isDate($0.date, inSameDayAs: now) }
            .map(\.durationSeconds)
            .reduce(0, +)
    }

    func dailyMark(for day: Date, goalSeconds: Int) -> DailyMark {
        let cal = Calendar.current
        let total = events
            .filter { cal.isDate($0.date, inSameDayAs: day) }
            .map(\.durationSeconds)
            .reduce(0, +)
        let symbol: DailyMark.Symbol
        if total == 0                     { symbol = .none }
        else if total >= goalSeconds * 2  { symbol = .exceeded }
        else if total >= goalSeconds      { symbol = .reached }
        else                              { symbol = .some }
        return DailyMark(day: cal.startOfDay(for: day), symbol: symbol, totalSeconds: total)
    }

    func daysSinceLastStudy(now: Date = .now) -> Int? {
        guard let last = events.map(\.date).max() else { return nil }
        let cal = Calendar.current
        return cal.dateComponents([.day],
                                  from: cal.startOfDay(for: last),
                                  to:   cal.startOfDay(for: now)).day
    }

    /// Most-recent unresolved mistake tag — used by recovery suggestions.
    func topStuckTagId() -> String? {
        stuckCounts.max(by: { $0.value < $1.value })?.key
    }

    private func unlockAchievement(_ id: String, at date: Date) {
        if let index = achievements.firstIndex(where: { $0.id == id }) {
            if achievements[index].earnedAt == nil {
                achievements[index].earnedAt = date
            }
        } else if var achievement = Self.defaultAchievements.first(where: { $0.id == id }) {
            achievement.earnedAt = date
            achievements.append(achievement)
        }
    }

    private func longestStreakDays() -> Int {
        let cal = Calendar.current
        let days = Set(events.map { cal.startOfDay(for: $0.date) }).sorted()
        var best = 0
        var current = 0
        var previous: Date?

        for day in days {
            if let previous,
               let next = cal.date(byAdding: .day, value: 1, to: previous),
               cal.isDate(next, inSameDayAs: day) {
                current += 1
            } else {
                current = 1
            }
            best = max(best, current)
            previous = day
        }
        return best
    }

    private static func mergedAchievements(from saved: [Achievement]) -> [Achievement] {
        defaultAchievements.map { defaultAchievement in
            saved.first(where: { $0.id == defaultAchievement.id }) ?? defaultAchievement
        }
    }

    static let defaultAchievements: [Achievement] = [
        Achievement(
            id: "first-solve",
            title: "はじめの一問",
            description: "最初の問題を最後まで解きました。",
            earnedAt: nil
        ),
        Achievement(
            id: "streak-3",
            title: "3日ルート",
            description: "3日続けて学習しました。",
            earnedAt: nil
        ),
        Achievement(
            id: "streak-7",
            title: "1週間ルート",
            description: "7日続けて学習しました。",
            earnedAt: nil
        ),
        Achievement(
            id: "streak-30",
            title: "30日ルート",
            description: "30日続けて学習しました。",
            earnedAt: nil
        ),
        Achievement(
            id: "first-practice",
            title: "ここだけ特訓クリア",
            description: "はじめて特訓問題を解きました。",
            earnedAt: nil
        ),
        Achievement(
            id: "unit-complete",
            title: "単元走破",
            description: "ひとつの単元の通常問題をすべて解きました。",
            earnedAt: nil
        ),
        Achievement(
            id: "diagnosis-complete",
            title: "ルート診断完了",
            description: "診断を終えて、自分のルートを見つけました。",
            earnedAt: nil
        )
    ]
}
