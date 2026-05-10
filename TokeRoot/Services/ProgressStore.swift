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

    func recordEvent(_ e: StudyEvent, data: DataService = .shared) {
        events.append(e)
        for tag in e.mistakeTagIds {
            stuckCounts[tag, default: 0] += 1
        }
        updateReviewSchedule(after: e, data: data)
        lastProblemId = e.problemId
        lastUnitId = e.unitId
        checkAchievements()
        save()
    }

    func addReview(_ item: ReviewItem) {
        if let index = reviewItems.firstIndex(where: { $0.problemId == item.problemId }) {
            let existing = reviewItems[index]
            let dueAt = min(existing.dueAt, item.dueAt)
            reviewItems[index] = ReviewItem(
                id: existing.id,
                problemId: existing.problemId,
                reason: item.reason,
                addedAt: existing.addedAt,
                dueAt: dueAt,
                intervalDays: min(existing.intervalDays, item.intervalDays),
                reviewedCount: existing.reviewedCount
            )
            save()
        } else {
            reviewItems.append(item)
            save()
        }
    }

    func removeReview(_ id: UUID) {
        reviewItems.removeAll { $0.id == id }
        save()
    }

    func dueReviewItems(now: Date = .now) -> [ReviewItem] {
        let today = Calendar.current.startOfDay(for: now)
        return reviewItems
            .filter { Calendar.current.startOfDay(for: $0.dueAt) <= today }
            .sorted { $0.dueAt < $1.dueAt }
    }

    func upcomingReviewItems(now: Date = .now) -> [ReviewItem] {
        let today = Calendar.current.startOfDay(for: now)
        return reviewItems
            .filter { Calendar.current.startOfDay(for: $0.dueAt) > today }
            .sorted { $0.dueAt < $1.dueAt }
    }

    func nextReviewDueDate(now: Date = .now) -> Date? {
        reviewItems
            .map(\.dueAt)
            .filter { $0 >= Calendar.current.startOfDay(for: now) }
            .min()
    }

    func clearCount(for problemId: String) -> Int {
        events.filter {
            $0.problemId == problemId
            && ($0.outcome == .solved || $0.outcome == .practice)
        }
        .count
    }

    func masterySlots(for problemId: String) -> Int {
        min(clearCount(for: problemId), 3)
    }

    func isMastered(problemId: String) -> Bool {
        masterySlots(for: problemId) >= 3
    }

    func familyKey(for problem: Problem) -> String {
        if let familyId = problem.familyId, !familyId.isEmpty {
            return "\(problem.unitId)|\(familyId)"
        }

        let broadTags: Set<String> = [
            "正負の数", "文字式", "一次方程式", "比例", "反比例", "図形",
            "式の計算", "連立方程式", "一次関数", "確率",
            "展開", "因数分解", "平方根", "二次方程式", "二次関数",
            "標準", "高校受験", "入試型", "自力", "特訓", "グラフ"
        ]
        let helperTags: Set<String> = ["文章題", "式立て"]
        let meaningfulTags = problem.tags.filter { !broadTags.contains($0) }
        let specificTag = meaningfulTags.first { !helperTags.contains($0) }
        let fallbackTag = meaningfulTags.first ?? problem.mode.rawValue
        return "\(problem.unitId)|\(specificTag ?? fallbackTag)"
    }

    func relatedProblems(to problem: Problem, data: DataService = .shared) -> [Problem] {
        let key = familyKey(for: problem)
        return data.problems(in: problem.unitId)
            .filter { familyKey(for: $0) == key }
            .sorted { lhs, rhs in
                if lhs.difficulty != rhs.difficulty {
                    return lhs.difficulty < rhs.difficulty
                }
                return lhs.id < rhs.id
            }
    }

    func distinctClearedCount(inFamilyOf problem: Problem, data: DataService = .shared) -> Int {
        let relatedIds = Set(relatedProblems(to: problem, data: data).map(\.id))
        let clearedIds = Set(events.filter {
            relatedIds.contains($0.problemId)
            && ($0.outcome == .solved || $0.outcome == .practice)
        }.map(\.problemId))
        return clearedIds.count
    }

    func familyClearProgressCount(for problem: Problem, data: DataService = .shared) -> Int {
        let relatedProblems = relatedProblems(to: problem, data: data)
        let relatedIds = Set(relatedProblems.map(\.id))
        let clearedEvents = events.filter {
            relatedIds.contains($0.problemId)
            && ($0.outcome == .solved || $0.outcome == .practice)
        }
        let distinctCount = Set(clearedEvents.map(\.problemId)).count

        if relatedProblems.count >= 3 {
            return distinctCount
        }
        if distinctCount < relatedProblems.count {
            return distinctCount
        }
        return clearedEvents.count
    }

    func familyMasterySlots(for problem: Problem, data: DataService = .shared) -> Int {
        min(familyClearProgressCount(for: problem, data: data), 3)
    }

    func isFamilyMastered(problem: Problem, data: DataService = .shared) -> Bool {
        familyMasterySlots(for: problem, data: data) >= 3
    }

    func familyCount(in unitId: String, data: DataService = .shared) -> Int {
        Set(data.problems(in: unitId).map { familyKey(for: $0) }).count
    }

    func masteredFamilyCount(in unitId: String, data: DataService = .shared) -> Int {
        let grouped = Dictionary(grouping: data.problems(in: unitId), by: { familyKey(for: $0) })
        return grouped.values.filter { family in
            guard let first = family.first else { return false }
            return isFamilyMastered(problem: first, data: data)
        }.count
    }

    func masteredCount(in unitId: String, data: DataService = .shared) -> Int {
        masteredFamilyCount(in: unitId, data: data)
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

    private func updateReviewSchedule(after event: StudyEvent, data: DataService) {
        guard event.outcome == .solved || event.outcome == .practice,
              let problem = data.problem(id: event.problemId),
              !problem.tags.contains("特訓") else {
            return
        }

        let hasMistake = !event.mistakeTagIds.isEmpty
        let reason: ReviewItem.Reason = hasMistake ? .mistake : .scheduled
        let nextDay = dueDate(daysFromNow: 1, now: event.date)

        if let index = reviewItems.firstIndex(where: { $0.problemId == event.problemId }) {
            let current = reviewItems[index]
            if hasMistake {
                reviewItems[index] = ReviewItem(
                    id: current.id,
                    problemId: current.problemId,
                    reason: .mistake,
                    addedAt: current.addedAt,
                    dueAt: nextDay,
                    intervalDays: 1,
                    reviewedCount: 0
                )
                return
            }

            let today = Calendar.current.startOfDay(for: event.date)
            guard Calendar.current.startOfDay(for: current.dueAt) <= today else {
                return
            }

            let nextReviewedCount = current.reviewedCount + 1
            let nextInterval = reviewIntervalDays(afterReviewedCount: nextReviewedCount)
            reviewItems[index] = ReviewItem(
                id: current.id,
                problemId: current.problemId,
                reason: .scheduled,
                addedAt: current.addedAt,
                dueAt: dueDate(daysFromNow: nextInterval, now: event.date),
                intervalDays: nextInterval,
                reviewedCount: nextReviewedCount
            )
        } else {
            reviewItems.append(ReviewItem(
                id: UUID(),
                problemId: event.problemId,
                reason: reason,
                addedAt: event.date,
                dueAt: nextDay,
                intervalDays: 1,
                reviewedCount: 0
            ))
        }
    }

    private func dueDate(daysFromNow days: Int, now: Date) -> Date {
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        return cal.date(byAdding: .day, value: days, to: today) ?? now
    }

    private func reviewIntervalDays(afterReviewedCount count: Int) -> Int {
        let intervals = [1, 3, 7, 14, 30]
        let index = min(max(count, 0), intervals.count - 1)
        return intervals[index]
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
