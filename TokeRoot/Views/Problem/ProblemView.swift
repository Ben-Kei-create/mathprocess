import PencilKit
import SwiftUI

/// The most important screen in the app. Stays visually clean: top
/// breadcrumb, equation card, prompt, choices, and three small tools.
struct ProblemView: View {
    let problemId: String
    /// If non-nil, called instead of `dismiss()` when the user finishes.
    /// Used by `PracticeRunnerView` to advance through a set inline.
    var onSolved: (() -> Void)? = nil

    @Environment(DataService.self) private var data
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var vm: ProblemViewModel?
    @State private var showMemo = false
    @State private var showCalculator = false
    @State private var selfMadeCanvas = PKCanvasView()
    @State private var selfMadeToolPicker = PKToolPicker()

    var body: some View {
        Group {
            if let vm {
                content(vm)
            } else {
                Color.clear
                    .onAppear {
                        if let p = data.problem(id: problemId) {
                            vm = ProblemViewModel(problem: p)
                        }
                    }
            }
        }
        .background(TKColor.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(toolbarTitle)
                    .font(TKType.caption)
                    .foregroundStyle(TKColor.textSecondary)
            }
        }
        .sheet(isPresented: $showMemo) { MemoSheet() }
        .sheet(isPresented: $showCalculator) { CalculatorSheet() }
    }

    @ViewBuilder
    private func content(_ vm: ProblemViewModel) -> some View {
        VStack(alignment: .leading, spacing: TKSpacing.lg) {
            progressLine(vm)

            EquationCard(text: vm.displayedEquation,
                         highlight: vm.displayedHighlight)
                .animation(.easeInOut(duration: 0.3), value: vm.displayedEquation)

            if let diagram = vm.problem.diagram {
                GeometryDiagramView(diagram: diagram)
            }

            captionView(vm)

            answerArea(vm)

            Spacer()

            footerActions(vm)
            toolBar(vm: vm)
        }
        .padding(.horizontal, TKSpacing.md)
        .padding(.top, TKSpacing.sm)
        .padding(.bottom, TKSpacing.md)
        .frame(maxWidth: horizontalSizeClass == .regular ? 860 : .infinity,
               alignment: .topLeading)
        .frame(maxWidth: .infinity)
    }

    private func progressLine(_ vm: ProblemViewModel) -> some View {
        HStack {
            Text("\(vm.stepIndex + 1) / \(vm.totalSteps)")
                .font(TKType.caption)
                .foregroundStyle(TKColor.textSecondary)
            Spacer()
            Text(vm.problem.title)
                .font(TKType.caption)
                .foregroundStyle(TKColor.textTertiary)
        }
    }

    private func captionView(_ vm: ProblemViewModel) -> some View {
        Text(vm.caption)
            .font(TKType.subtitle)
            .foregroundStyle(captionColor(vm.phase))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(TKSpacing.md)
            .background(captionBg(vm.phase))
            .clipShape(RoundedRectangle(cornerRadius: TKRadius.medium))
            .animation(.easeInOut(duration: 0.2), value: vm.phase)
    }

    private func captionColor(_ p: ProblemViewModel.Phase) -> Color {
        switch p {
        case .wrongShown: return TKColor.warm
        case .revealed, .solved: return TKColor.success
        default: return TKColor.textPrimary
        }
    }
    private func captionBg(_ p: ProblemViewModel.Phase) -> Color {
        switch p {
        case .wrongShown:        return TKColor.warmSoft
        case .revealed, .solved: return TKColor.successSoft
        default:                 return TKColor.surfaceElevated
        }
    }

    @ViewBuilder
    private func answerArea(_ vm: ProblemViewModel) -> some View {
        if vm.phase == .solved {
            EmptyView()
        } else {
            switch vm.problem.mode {
            case .fillIn:
                fillInAnswer(vm)
            case .selfMade:
                selfMadeAnswer(vm)
            case .nextMove:
                choices(vm)
            }

            if vm.showHint {
                HStack(alignment: .top, spacing: TKSpacing.sm) {
                    Image(systemName: "lightbulb")
                        .foregroundStyle(TKColor.warm)
                    Text(vm.problem.hint)
                        .font(TKType.body)
                        .foregroundStyle(TKColor.textSecondary)
                }
                .padding(TKSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(TKColor.warmSoft)
                .clipShape(RoundedRectangle(cornerRadius: TKRadius.medium))
            }
        }
    }

    private func choices(_ vm: ProblemViewModel) -> some View {
        LazyVGrid(columns: choiceColumns, spacing: TKSpacing.sm) {
            ForEach(vm.currentStep.choices) { choice in
                ChoiceButton(label: choice.label,
                             state: vm.choiceState(for: choice)) {
                    vm.tap(choice: choice)
                }
                .disabled(vm.phase != .prompt)
            }
        }
    }

    private func fillInAnswer(_ vm: ProblemViewModel) -> some View {
        VStack(alignment: .leading, spacing: TKSpacing.sm) {
            TextField("次の式を入力", text: Binding(
                get: { vm.fillInText },
                set: { vm.fillInText = $0 }
            ))
            .font(TKType.subtitle)
            .foregroundStyle(TKColor.textPrimary)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .submitLabel(.done)
            .disabled(vm.phase != .prompt)
            .onSubmit { vm.submitFillInAnswer() }
            .padding(.horizontal, TKSpacing.md + 2)
            .padding(.vertical, TKSpacing.md + 2)
            .background(TKColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: TKRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: TKRadius.medium)
                    .stroke(fillInStroke(vm.phase), lineWidth: 1.2)
            )

            if let feedback = vm.fillInFeedbackLabel {
                ChoiceButton(label: feedback,
                             state: vm.fillInFeedbackState) {}
                    .disabled(true)
            }

            if vm.phase == .prompt {
                PrimaryButton("答え合わせ", systemImage: "checkmark") {
                    vm.submitFillInAnswer()
                }
                .disabled(!vm.canSubmitFillInAnswer)
                .opacity(vm.canSubmitFillInAnswer ? 1 : 0.45)
            }
        }
        .frame(maxWidth: horizontalSizeClass == .regular ? 560 : .infinity,
               alignment: .leading)
    }

    private var choiceColumns: [GridItem] {
        let count = horizontalSizeClass == .regular ? 2 : 1
        return Array(
            repeating: GridItem(.flexible(), spacing: TKSpacing.sm, alignment: .top),
            count: count
        )
    }

    private func fillInStroke(_ phase: ProblemViewModel.Phase) -> Color {
        switch phase {
        case .wrongShown:        return TKColor.warm.opacity(0.6)
        case .revealed:          return TKColor.success.opacity(0.6)
        default:                 return TKColor.divider
        }
    }

    private func selfMadeAnswer(_ vm: ProblemViewModel) -> some View {
        VStack(alignment: .leading, spacing: TKSpacing.sm) {
            Text("途中式メモ")
                .font(TKType.caption)
                .foregroundStyle(TKColor.textSecondary)

            DrawingCanvasView(
                canvas: selfMadeCanvas,
                toolPicker: selfMadeToolPicker,
                becomesFirstResponder: false
            )
            .frame(minHeight: horizontalSizeClass == .regular ? 300 : 220)
            .background(TKColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: TKRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: TKRadius.medium)
                    .stroke(TKColor.divider, lineWidth: 1.2)
            )

            Button {
                selfMadeCanvas.drawing = PKDrawing()
            } label: {
                Label("メモを消す", systemImage: "eraser")
                    .font(TKType.caption)
                    .foregroundStyle(TKColor.textSecondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: TKSpacing.xs) {
                Text("答えの値")
                    .font(TKType.caption)
                    .foregroundStyle(TKColor.textSecondary)

                TextField("例: 5", text: Binding(
                    get: { vm.selfMadeAnswerText },
                    set: { vm.updateSelfMadeAnswerText($0) }
                ))
                .font(TKType.subtitle)
                .foregroundStyle(TKColor.textPrimary)
                .keyboardType(.numbersAndPunctuation)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .onSubmit { vm.submitSelfMadeAnswer() }
                .padding(.horizontal, TKSpacing.md + 2)
                .padding(.vertical, TKSpacing.md + 2)
                .background(TKColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: TKRadius.medium))
                .overlay(
                    RoundedRectangle(cornerRadius: TKRadius.medium)
                        .stroke(selfMadeStroke(vm), lineWidth: 1.2)
                )
                .frame(maxWidth: horizontalSizeClass == .regular ? 240 : .infinity)

                Text("x = は書いても、書かなくてもOK")
                    .font(TKType.caption)
                    .foregroundStyle(TKColor.textTertiary)
            }

            if let feedback = vm.selfMadeFeedbackLabel {
                ChoiceButton(label: feedback,
                             state: vm.selfMadeFeedbackState) {}
                    .disabled(true)
            }

            PrimaryButton("答え合わせ", systemImage: "checkmark") {
                vm.submitSelfMadeAnswer()
            }
            .disabled(!vm.canSubmitSelfMadeAnswer)
            .opacity(vm.canSubmitSelfMadeAnswer ? 1 : 0.45)
        }
    }

    @ViewBuilder
    private func footerActions(_ vm: ProblemViewModel) -> some View {
        switch vm.phase {
        case .revealed:
            PrimaryButton("次へ", systemImage: "arrow.right") { vm.advance() }
        case .wrongShown:
            VStack(spacing: TKSpacing.sm) {
                if vm.problem.mode == .selfMade {
                    HStack(spacing: TKSpacing.sm) {
                        PrimaryButton("入力を直す", style: .soft) { vm.retryStep() }
                        PrimaryButton("ヒント", style: .outline) { vm.showHint = true }
                    }
                } else {
                    if let tagId = vm.suggestedMistakeTagId,
                       let tag = data.mistakeTag(id: tagId) {
                        NavigationLink(value: HomeView.NavTarget.practice(tag.practiceSetId)) {
                            Text("ここだけ特訓する: \(tag.label)")
                                .font(TKType.subtitle)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, TKSpacing.md)
                                .background(TKColor.accent)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: TKRadius.large))
                        }
                        .buttonStyle(.plain)
                    }
                    HStack(spacing: TKSpacing.sm) {
                        PrimaryButton("もう一度", style: .soft) { vm.retryStep() }
                        PrimaryButton("ヒント", style: .outline) { vm.showHint = true }
                    }
                }
            }
        case .solved:
            VStack(spacing: TKSpacing.sm) {
                PrimaryButton(onSolved == nil ? "おわる" : "次の問題へ",
                              systemImage: "checkmark") {
                    if let onSolved { onSolved() } else { dismiss() }
                }
                Button {
                    let item = ReviewItem(id: UUID(),
                                          problemId: vm.problem.id,
                                          reason: .shaky,
                                          addedAt: .now)
                    ProgressStore.shared.addReview(item)
                } label: {
                    Text("ふくしゅう箱に入れる")
                        .font(TKType.caption)
                        .foregroundStyle(TKColor.textSecondary)
                }
            }
        case .prompt:
            EmptyView()
        }
    }

    private func toolBar(vm: ProblemViewModel) -> some View {
        HStack(spacing: TKSpacing.lg) {
            toolBtn("メモ",   icon: "square.and.pencil") { showMemo = true }
            toolBtn("ヒント", icon: "lightbulb") { vm.showHint.toggle() }
            toolBtn("計算機", icon: "function")  { showCalculator = true }
        }
        .frame(maxWidth: .infinity)
    }

    private func toolBtn(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                Text(title)
                    .font(TKType.caption)
            }
            .foregroundStyle(TKColor.textSecondary)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private var toolbarTitle: String {
        guard let vm,
              let unit = data.unit(id: vm.problem.unitId) else {
            return "解け√ルート"
        }
        return "\(unit.grade.rawValue) > \(unit.title)"
    }

    private func selfMadeStroke(_ vm: ProblemViewModel) -> Color {
        guard vm.lastSelfMadeAnswerWasCorrect != nil else {
            return TKColor.divider
        }
        return vm.lastSelfMadeAnswerWasCorrect == true
            ? TKColor.success.opacity(0.6)
            : TKColor.warm.opacity(0.6)
    }
}
