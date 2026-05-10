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
    private let answerJudge: AnswerJudgeService
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
    var fillInText: String = ""
    var lastSubmittedFillInText: String? = nil
    var selfMadeAnswerText: String = ""
    var lastSubmittedSelfMadeAnswerText: String? = nil
    var lastSelfMadeAnswerWasCorrect: Bool? = nil
    var selfMadeRecognitionMessage: String? = nil
    var selfMadeHadWrongAttempt: Bool = false
    var encounteredMistakeTagIds: Set<String> = []
    var showHint: Bool = false

    init(problem: Problem,
         store: ProgressStore = .shared,
         data: DataService = .shared,
         answerJudge: AnswerJudgeService = .shared) {
        self.problem = problem
        self.store = store
        self.data = data
        self.answerJudge = answerJudge
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
            if problem.mode == .selfMade {
                return "もう少し。メモはそのままで大丈夫。答えの値だけ見直して、もう一度答え合わせしてみましょう。"
            }
            if let id = tagId, let tag = data.mistakeTag(id: id) {
                return "惜しい。" + tag.kindMessage
            }
            return "惜しい。もう一度考えてみましょう。"
        case .revealed:              return currentStep.explanationCaption
        case .solved:
            if problem.mode == .selfMade {
                if selfMadeHadWrongAttempt {
                    return "答えは \(problem.finalAnswer) です。見直してたどり着けました。"
                }
                return "答えは \(problem.finalAnswer) です。自分で最後まで進められました。"
            }
            return "答えは \(problem.finalAnswer) です。よくできました。"
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

    func submitFillInAnswer() {
        guard problem.mode == .fillIn, phase == .prompt, canSubmitFillInAnswer else { return }

        let submitted = fillInText.trimmingCharacters(in: .whitespacesAndNewlines)
        let matchedChoice = choice(matchingFillInAnswer: submitted)
        lastSubmittedFillInText = submitted

        if matchedChoice?.isCorrect == true {
            withAnimation(.easeInOut(duration: 0.25)) {
                phase = .revealed
            }
        } else {
            let mistakeTagId = matchedChoice?.mistakeTagId
                ?? currentStep.choices.first(where: { !$0.isCorrect })?.mistakeTagId
            if let mistakeTagId {
                encounteredMistakeTagIds.insert(mistakeTagId)
            }
            withAnimation(.easeInOut(duration: 0.2)) {
                phase = .wrongShown(mistakeTagId: mistakeTagId)
            }
        }
    }

    func updateSelfMadeAnswerText(_ value: String) {
        selfMadeAnswerText = value
        selfMadeRecognitionMessage = nil
        guard let lastSubmittedSelfMadeAnswerText,
              value != lastSubmittedSelfMadeAnswerText else {
            return
        }
        self.lastSubmittedSelfMadeAnswerText = nil
        lastSelfMadeAnswerWasCorrect = nil
        if case .wrongShown = phase {
            withAnimation(.easeInOut(duration: 0.18)) {
                phase = .prompt
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
                resetFillInInput()
            }
        }
    }

    func retryStep() {
        withAnimation(.easeInOut(duration: 0.18)) {
            phase = .prompt
            lastTappedChoiceId = nil
            resetFillInInput()
            resetSelfMadeInput()
        }
    }

    func submitRecognizedSelfMadeAnswer(_ recognizedText: String) {
        selfMadeAnswerText = recognizedText
        submitSelfMadeAnswer(sourceMessage: "読み取り: \(recognizedText)")
    }

    func showSelfMadeRecognitionError(_ message: String) {
        selfMadeRecognitionMessage = message
        lastSubmittedSelfMadeAnswerText = nil
        lastSelfMadeAnswerWasCorrect = nil
    }

    func clearSelfMadeAnswerInput() {
        selfMadeAnswerText = ""
        resetSelfMadeInput()
        if case .wrongShown = phase {
            withAnimation(.easeInOut(duration: 0.18)) {
                phase = .prompt
            }
        }
    }

    func submitSelfMadeAnswer(sourceMessage: String? = nil) {
        guard problem.mode == .selfMade,
              phase != .solved,
              canSubmitSelfMadeAnswer else {
            return
        }

        let submitted = selfMadeAnswerText.trimmingCharacters(in: .whitespacesAndNewlines)
        let isCorrect = answerJudge.isCorrect(submitted, for: problem)
        selfMadeRecognitionMessage = sourceMessage
        lastSubmittedSelfMadeAnswerText = submitted
        lastSelfMadeAnswerWasCorrect = isCorrect

        if isCorrect {
            withAnimation(.easeInOut(duration: 0.25)) {
                phase = .solved
            }
            recordOutcome(outcome: selfMadeHadWrongAttempt ? .practice : .solved)
        } else {
            selfMadeHadWrongAttempt = true
            withAnimation(.easeInOut(duration: 0.2)) {
                phase = .wrongShown(mistakeTagId: nil)
            }
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

    var canSubmitFillInAnswer: Bool {
        !fillInText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canSubmitSelfMadeAnswer: Bool {
        !selfMadeAnswerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var fillInFeedbackLabel: String? {
        guard let lastSubmittedFillInText else { return nil }
        return "入力: \(lastSubmittedFillInText)"
    }

    var fillInFeedbackState: ChoiceButton.State {
        phase == .revealed ? .correct : .wrong
    }

    var selfMadeFeedbackLabel: String? {
        guard let lastSubmittedSelfMadeAnswerText else { return nil }
        return "入力: \(lastSubmittedSelfMadeAnswerText)"
    }

    var selfMadeFeedbackState: ChoiceButton.State {
        lastSelfMadeAnswerWasCorrect == true ? .correct : .wrong
    }

    /// Suggested mistake tag (the one most relevant for recovery).
    var suggestedMistakeTagId: String? {
        if case .wrongShown(let id) = phase, let id { return id }
        return encounteredMistakeTagIds.first
    }

    private func recordOutcome(outcome: StudyEvent.Outcome? = nil) {
        let elapsed = Int(Date().timeIntervalSince(startedAt))
        let event = StudyEvent(
            id: UUID(),
            date: .now,
            unitId: problem.unitId,
            problemId: problem.id,
            durationSeconds: max(elapsed, 5),
            outcome: outcome ?? (encounteredMistakeTagIds.isEmpty ? .solved : .practice),
            mistakeTagIds: Array(encounteredMistakeTagIds)
        )
        store.recordEvent(event)
    }

    private func choice(matchingFillInAnswer answer: String) -> ProblemStep.Choice? {
        let normalizedAnswer = normalizedFillInAnswer(answer)
        return currentStep.choices.first {
            normalizedFillInAnswer($0.label) == normalizedAnswer
        }
    }

    private func normalizedFillInAnswer(_ value: String) -> String {
        let halfWidth = value.applyingTransform(.fullwidthToHalfwidth, reverse: false) ?? value
        return halfWidth
            .filter { !$0.isWhitespace && !$0.isNewline }
            .lowercased()
    }

    private func resetFillInInput() {
        fillInText = ""
        lastSubmittedFillInText = nil
    }

    private func resetSelfMadeInput() {
        selfMadeAnswerText = ""
        lastSubmittedSelfMadeAnswerText = nil
        lastSelfMadeAnswerWasCorrect = nil
        selfMadeRecognitionMessage = nil
    }
}
