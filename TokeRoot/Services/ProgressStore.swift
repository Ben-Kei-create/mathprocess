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
    var stuckCounts: [String: Int] = [:]    // mistakeTagId -> count
    var solvedProblemIds: Set<String> = []  // problems cleared at least once
    var attemptsByProblem: [String: Int] = [:]  // problemId -> attempts

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
        var stuckCounts: [String: Int]
        var solvedProblemIds: [String]?       // optional for old snapshots
        var attemptsByProblem: [String: Int]?
    }

    func save() {
        let snap = Snapshot(
            profile: profile,
            events: events,
            reviewItems: reviewItems,
            lastProblemId: lastProblemId,
            lastUnitId: lastUnitId,
            memoText: memoText,
            stuckCounts: stuckCounts,
            solvedProblemIds: Array(solvedProblemIds),
            attemptsByProblem: attemptsByProblem
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
        self.stuckCounts = snap.stuckCounts
        self.solvedProblemIds = Set(snap.solvedProblemIds ?? [])
        self.attemptsByProblem = snap.attemptsByProblem ?? [:]
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
        stuckCounts = [:]
        solvedProblemIds = []
        attemptsByProblem = [:]
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
