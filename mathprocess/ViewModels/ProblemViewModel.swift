import Foundation
import SwiftUI

/// State machine for one problem run.
///
/// Phases:
///  - `prompt`     — equationBefore + choices visible, awaiting tap
///  - `wrongShown` — a wrong choice was tapped; "惜しい。" banner up
///  - `revealed`   — correct chosen; equationAfter + caption shown, "次へ" enabled
///  - `solved`     — final step cleared; recap shown
@Observable
final class ProblemViewModel {
    let problem: Problem
    private let store: ProgressStore
    private let data: DataService
    private let startedAt: Date

    enum Phase: Equatable {
        case prompt
        case wrongShown(mistakeTagId: String?)
        case revealed
        case solved
    }

    var stepIndex: Int = 0
    var phase: Phase = .prompt
    var lastTappedChoiceId: String? = nil
    var encounteredMistakeTagIds: Set<String> = []
    var showHint: Bool = false

    /// True if recording this solve raised the user's max cleared
    /// difficulty in this unit. Drives the "新しい考え方が1つ増えた" banner.
    var didAdvanceLevel: Bool = false
    var advancedLevelConcept: String? = nil

    init(problem: Problem,
         store: ProgressStore = .shared,
         data: DataService = .shared) {
        self.problem = problem
        self.store = store
        self.data = data
        self.startedAt = Date()
    }

    var currentStep: ProblemStep { problem.steps[stepIndex] }
    var totalSteps: Int { problem.steps.count }

    /// Equation visible in the card right now.
    var displayedEquation: String {
        switch phase {
        case .prompt, .wrongShown: return currentStep.equationBefore
        case .revealed:            return currentStep.equationAfter
        case .solved:              return problem.finalAnswer
        }
    }

    var displayedHighlight: String? {
        phase == .revealed ? currentStep.highlight : nil
    }

    var caption: String {
        switch phase {
        case .prompt:                return currentStep.prompt
        case .wrongShown(let tagId):
            if let id = tagId, let tag = data.mistakeTag(id: id) {
                return "惜しい。" + tag.kindMessage
            }
            return "惜しい。もう一度考えてみましょう。"
        case .revealed:              return currentStep.explanationCaption
        case .solved:                return "答えは \(problem.finalAnswer) です。よくできました。"
        }
    }

    func tap(choice: ProblemStep.Choice) {
        lastTappedChoiceId = choice.id
        if choice.isCorrect {
            withAnimation(.easeInOut(duration: 0.25)) {
                phase = .revealed
            }
        } else {
            if let tag = choice.mistakeTagId {
                encounteredMistakeTagIds.insert(tag)
            }
            withAnimation(.easeInOut(duration: 0.2)) {
                phase = .wrongShown(mistakeTagId: choice.mistakeTagId)
            }
        }
    }

    func advance() {
        guard phase == .revealed else { return }
        if stepIndex + 1 >= problem.steps.count {
            withAnimation(.easeInOut) { phase = .solved }
            recordOutcome()
        } else {
            withAnimation(.easeInOut(duration: 0.25)) {
                stepIndex += 1
                phase = .prompt
                lastTappedChoiceId = nil
            }
        }
    }

    func retryStep() {
        withAnimation(.easeInOut(duration: 0.18)) {
            phase = .prompt
            lastTappedChoiceId = nil
        }
    }

    func choiceState(for choice: ProblemStep.Choice) -> ChoiceButton.State {
        switch phase {
        case .prompt:
            return .idle
        case .wrongShown:
            if choice.id == lastTappedChoiceId { return .wrong }
            return .dimmed
        case .revealed, .solved:
            if choice.isCorrect { return .correct }
            return .dimmed
        }
    }

    /// Suggested mistake tag (the one most relevant for recovery).
    var suggestedMistakeTagId: String? {
        if case .wrongShown(let id) = phase, let id { return id }
        return encounteredMistakeTagIds.first
    }

    private func recordOutcome() {
        let engine = RouteEngine(data: data, store: store)
        let beforeLv = engine.clearedDifficulty(in: problem.unitId)

        let elapsed = Int(Date().timeIntervalSince(startedAt))
        let event = StudyEvent(
            id: UUID(),
            date: .now,
            unitId: problem.unitId,
            problemId: problem.id,
            durationSeconds: max(elapsed, 5),
            outcome: encounteredMistakeTagIds.isEmpty ? .solved : .practice,
            mistakeTagIds: Array(encounteredMistakeTagIds)
        )
        store.recordEvent(event)

        let afterLv = engine.clearedDifficulty(in: problem.unitId)
        if afterLv > beforeLv {
            didAdvanceLevel = true
            advancedLevelConcept = data.levelConcept(unitId: problem.unitId, level: afterLv)
        }
    }
}
