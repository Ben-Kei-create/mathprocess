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
    var lastProblemId: String? = nil
    var lastUnitId: String? = nil
    var memoText: String = ""
    var memoDrawingData: Data = Data()
    var stuckCounts: [String: Int] = [:]        // mistakeTagId -> count
    var solvedProblemIds: Set<String> = []      // problems cleared at least once
    var attemptsByProblem: [String: Int] = [:]  // problemId -> attempt count

    /// Per (unitId : level) consecutive perfect (no-mistake) clears.
    /// Key format: `"unitId:lv"`. Reset on any non-perfect attempt.
    var perfectStreakByUnitLv: [String: Int] = [:]
    /// Per unit, the highest level early-unlocked by a 3-perfect bonus.
    /// `bonusUnlockedLevels[unitId] = N` means Lv.N is open even if the
    /// base difficulty gate hasn't been satisfied.
    var bonusUnlockedLevels: [String: Int] = [:]
    /// Transient (not persisted) one-shot signal: the last `recordEvent`
    /// call just earned a bonus unlock. ProblemViewModel reads + clears.
    var pendingBonus: PendingBonus? = nil

    struct PendingBonus: Equatable {
        let unitId: String
        let earnedAtLv: Int   // the level the user was perfect at
        let unlockedLv: Int   // the level newly opened (earnedAt + 2)
    }

    private let key = "tokeroot.progress.v1"

    private init() { load() }

    // MARK: persistence

    private struct Snapshot: Codable {
        var profile: UserProfile
        var events: [StudyEvent]
        var reviewItems: [ReviewItem]
        var lastProblemId: String?
        var lastUnitId: String?
        var memoText: String
        var memoDrawingData: Data
        var stuckCounts: [String: Int]
        var solvedProblemIds: [String]?
        var attemptsByProblem: [String: Int]?
        var perfectStreakByUnitLv: [String: Int]?
        var bonusUnlockedLevels: [String: Int]?

        init(profile: UserProfile,
             events: [StudyEvent],
             reviewItems: [ReviewItem],
             lastProblemId: String?,
             lastUnitId: String?,
             memoText: String,
             memoDrawingData: Data,
             stuckCounts: [String: Int],
             solvedProblemIds: [String],
             attemptsByProblem: [String: Int],
             perfectStreakByUnitLv: [String: Int],
             bonusUnlockedLevels: [String: Int]) {
            self.profile = profile
            self.events = events
            self.reviewItems = reviewItems
            self.lastProblemId = lastProblemId
            self.lastUnitId = lastUnitId
            self.memoText = memoText
            self.memoDrawingData = memoDrawingData
            self.stuckCounts = stuckCounts
            self.solvedProblemIds = solvedProblemIds
            self.attemptsByProblem = attemptsByProblem
            self.perfectStreakByUnitLv = perfectStreakByUnitLv
            self.bonusUnlockedLevels = bonusUnlockedLevels
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            profile               = try c.decode(UserProfile.self,            forKey: .profile)
            events                = try c.decode([StudyEvent].self,           forKey: .events)
            reviewItems           = try c.decode([ReviewItem].self,           forKey: .reviewItems)
            lastProblemId         = try c.decodeIfPresent(String.self,        forKey: .lastProblemId)
            lastUnitId            = try c.decodeIfPresent(String.self,        forKey: .lastUnitId)
            memoText              = try c.decode(String.self,                 forKey: .memoText)
            memoDrawingData       = try c.decodeIfPresent(Data.self,          forKey: .memoDrawingData) ?? Data()
            stuckCounts           = try c.decode([String: Int].self,          forKey: .stuckCounts)
            solvedProblemIds      = try c.decodeIfPresent([String].self,      forKey: .solvedProblemIds)
            attemptsByProblem     = try c.decodeIfPresent([String: Int].self, forKey: .attemptsByProblem)
            perfectStreakByUnitLv = try c.decodeIfPresent([String: Int].self, forKey: .perfectStreakByUnitLv)
            bonusUnlockedLevels   = try c.decodeIfPresent([String: Int].self, forKey: .bonusUnlockedLevels)
        }
    }

    func save() {
        let snap = Snapshot(
            profile: profile,
            events: events,
            reviewItems: reviewItems,
            lastProblemId: lastProblemId,
            lastUnitId: lastUnitId,
            memoText: memoText,
            memoDrawingData: memoDrawingData,
            stuckCounts: stuckCounts,
            solvedProblemIds: Array(solvedProblemIds),
            attemptsByProblem: attemptsByProblem,
            perfectStreakByUnitLv: perfectStreakByUnitLv,
            bonusUnlockedLevels: bonusUnlockedLevels
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
        self.lastProblemId = snap.lastProblemId
        self.lastUnitId = snap.lastUnitId
        self.memoText = snap.memoText
        self.memoDrawingData = snap.memoDrawingData
        self.stuckCounts = snap.stuckCounts
        self.solvedProblemIds = Set(snap.solvedProblemIds ?? [])
        self.attemptsByProblem = snap.attemptsByProblem ?? [:]
        self.perfectStreakByUnitLv = snap.perfectStreakByUnitLv ?? [:]
        self.bonusUnlockedLevels = snap.bonusUnlockedLevels ?? [:]
    }

    // MARK: mutations

    func recordEvent(_ e: StudyEvent) {
        events.append(e)
        for tag in e.mistakeTagIds {
            stuckCounts[tag, default: 0] += 1
        }
        attemptsByProblem[e.problemId, default: 0] += 1
        if e.outcome == .solved || e.outcome == .practice {
            solvedProblemIds.insert(e.problemId)
        }
        lastProblemId = e.problemId
        lastUnitId = e.unitId
        save()
    }

    /// Called by ProblemViewModel when a *main* (non-特訓) problem is
    /// solved with no mistakes. Tracks the perfect streak for that
    /// (unit, level) and, if it hits 3, opens Lv.+2 ahead of schedule.
    func recordPerfectClear(unitId: String, level: Int) {
        let key = "\(unitId):\(level)"
        let next = perfectStreakByUnitLv[key, default: 0] + 1
        perfectStreakByUnitLv[key] = next
        if next >= 3 {
            let bonusLv = level + 2
            let cur = bonusUnlockedLevels[unitId] ?? 0
            if bonusLv > cur {
                bonusUnlockedLevels[unitId] = bonusLv
                pendingBonus = PendingBonus(unitId: unitId,
                                            earnedAtLv: level,
                                            unlockedLv: bonusLv)
            }
            // Reset so the user has to do another 3 to earn again.
            perfectStreakByUnitLv[key] = 0
        }
        save()
    }

    /// Called when a problem at this level was solved with at least one
    /// wrong tap — resets the perfect streak for that level only.
    func breakPerfectStreak(unitId: String, level: Int) {
        let key = "\(unitId):\(level)"
        if perfectStreakByUnitLv[key] != 0 {
            perfectStreakByUnitLv[key] = 0
            save()
        }
    }

    /// Read & clear the one-shot bonus signal.
    func consumePendingBonus() -> PendingBonus? {
        defer { pendingBonus = nil }
        return pendingBonus
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
        lastProblemId = nil
        lastUnitId = nil
        memoText = ""
        memoDrawingData = Data()
        stuckCounts = [:]
        solvedProblemIds = []
        attemptsByProblem = [:]
        perfectStreakByUnitLv = [:]
        bonusUnlockedLevels = [:]
        pendingBonus = nil
        save()
    }

    func isSolved(_ problemId: String) -> Bool {
        solvedProblemIds.contains(problemId)
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
}
