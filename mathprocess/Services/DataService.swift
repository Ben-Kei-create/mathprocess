import Foundation

/// Loads all bundled JSON content once at launch and exposes typed
/// in-memory collections. Pure read-only — write state lives in
/// `ProgressStore`.
@Observable
final class DataService {
    static let shared = DataService()

    private(set) var units: [MathUnit] = []
    private(set) var problems: [Problem] = []
    private(set) var practiceSets: [PracticeSet] = []
    private(set) var mistakeTags: [MistakeTag] = []
    private(set) var diagnosisProblems: [DiagnosisProblem] = []
    private(set) var homeMessages: HomeMessages = .empty
    /// `[unitId: [difficulty (as String): concept message]]`
    private(set) var levelConcepts: [String: [String: String]] = [:]

    private init() { loadAll() }

    func loadAll() {
        units = decode("units") ?? []

        // Merge problem files. New units drop in here as additional files.
        let linearEq:   [Problem] = decode("problems_linear_eq")  ?? []
        let seifu:      [Problem] = decode("problems_seifu")      ?? []
        let mojishiki:  [Problem] = decode("problems_mojishiki")  ?? []
        let linearFn:   [Problem] = decode("problems_linear_fn")  ?? []
        let quadEq:     [Problem] = decode("problems_quad_eq")    ?? []
        problems = linearEq + seifu + mojishiki + linearFn + quadEq

        practiceSets      = decode("practice_sets")       ?? []
        mistakeTags       = decode("mistake_tags")        ?? []
        diagnosisProblems = decode("diagnosis_linear_eq") ?? []
        homeMessages      = decode("home_messages")       ?? .empty
        levelConcepts     = decode("level_concepts")      ?? [:]
    }

    /// Concept text introduced at this difficulty level. e.g.
    /// `levelConcept(unitId: "g1-linear-eq", level: 3)` →
    /// 「両辺に x があるときの移項」
    func levelConcept(unitId: String, level: Int) -> String? {
        levelConcepts[unitId]?["\(level)"]
    }

    // MARK: lookup helpers

    func unit(id: String) -> MathUnit? { units.first { $0.id == id } }
    func problem(id: String) -> Problem? { problems.first { $0.id == id } }
    func practiceSet(id: String) -> PracticeSet? { practiceSets.first { $0.id == id } }
    func mistakeTag(id: String) -> MistakeTag? { mistakeTags.first { $0.id == id } }

    /// Main learning sequence for a unit — excludes 特訓 sub-problems
    /// (those are reached via `practiceSet(id:)`).
    func problems(in unitId: String) -> [Problem] {
        problems.filter { $0.unitId == unitId && !$0.tags.contains("特訓") }
    }

    func diagnosis(for unitId: String) -> [DiagnosisProblem] {
        diagnosisProblems
            .filter { $0.unitId == unitId }
            .sorted { $0.order < $1.order }
    }

    // MARK: private

    private func decode<T: Decodable>(_ name: String) -> T? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}

struct HomeMessages: Codable {
    var comeback: [String]
    var shortTime: [String]
    var sportsBusy: [String]
    var lessonsBusy: [String]
    var stuck: [String]
    var progressing: [String]
    var `default`: [String]

    static let empty = HomeMessages(
        comeback: [], shortTime: [], sportsBusy: [], lessonsBusy: [],
        stuck: [], progressing: [], default: ["今日もここに来てくれてありがとうございます。"]
    )
}
