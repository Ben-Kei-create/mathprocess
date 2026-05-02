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

    @State private var vm: ProblemViewModel?
    @State private var showMemo = false
    @State private var showCalculator = false

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
                Text("中1 > 一次方程式")
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

            captionView(vm)

            choices(vm)

            Spacer()

            footerActions(vm)
            toolBar(vm: vm)
        }
        .padding(.horizontal, TKSpacing.md)
        .padding(.top, TKSpacing.sm)
        .padding(.bottom, TKSpacing.md)
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
    private func choices(_ vm: ProblemViewModel) -> some View {
        if vm.phase == .solved {
            EmptyView()
        } else {
            VStack(spacing: TKSpacing.sm) {
                ForEach(vm.currentStep.choices) { choice in
                    ChoiceButton(label: choice.label,
                                 state: vm.choiceState(for: choice)) {
                        vm.tap(choice: choice)
                    }
                    .disabled(vm.phase != .prompt)
                }
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

    @ViewBuilder
    private func footerActions(_ vm: ProblemViewModel) -> some View {
        switch vm.phase {
        case .revealed:
            PrimaryButton("次へ", systemImage: "arrow.right") { vm.advance() }
        case .wrongShown:
            VStack(spacing: TKSpacing.sm) {
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
        case .solved:
            VStack(spacing: TKSpacing.sm) {
                if vm.didAdvanceLevel {
                    LevelUpBanner(level: vm.problem.difficulty,
                                  concept: vm.advancedLevelConcept)
                }
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
}
