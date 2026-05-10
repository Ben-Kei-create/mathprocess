import PencilKit
import SwiftUI

/// The most important screen in the app. Stays visually clean: top
/// breadcrumb, equation card, prompt, choices, and three small tools.
struct ProblemView: View {
    private static let hintAnchorId = "problem-hint"

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
    @State private var showWorkPad = false
    @State private var workCanvas = PKCanvasView()
    @State private var workToolPicker = PKToolPicker()
    @State private var selfMadeCanvas = PKCanvasView()
    @State private var selfMadeToolPicker = PKToolPicker()
    @State private var handwrittenAnswerCanvas = PKCanvasView()
    @State private var handwrittenAnswerToolPicker = PKToolPicker()
    @State private var isRecognizingHandwriting = false
    @State private var showGeometryPointLabels = true
    @State private var showGeometryAngleNames = true
    @State private var showGeometryMeasurements = true

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
        .toolbar(.hidden, for: .tabBar)
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
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: TKSpacing.lg) {
                        progressLine(vm)

                        EquationCard(text: vm.displayedEquation,
                                     highlight: vm.displayedHighlight)
                            .animation(.easeInOut(duration: 0.3), value: vm.displayedEquation)

                        if let diagram = vm.problem.diagram {
                            geometryDiagram(diagram)
                        }

                        if let graph = vm.problem.graph {
                            CartesianGraphView(graph: graph)
                        }

                        captionView(vm)

                        inlineWorkPad(vm)

                        answerArea(vm)
                    }
                    .padding(.horizontal, TKSpacing.md)
                    .padding(.top, TKSpacing.sm)
                    .padding(.bottom, TKSpacing.md)
                }

                footerActions(vm, proxy: proxy)
                    .padding(.horizontal, TKSpacing.md)
                    .padding(.bottom, TKSpacing.sm)
                toolBar(vm: vm, proxy: proxy)
                    .padding(.horizontal, TKSpacing.md)
                    .padding(.bottom, TKSpacing.md)
            }
        }
        .frame(maxWidth: horizontalSizeClass == .regular ? 860 : .infinity,
               alignment: .topLeading)
        .frame(maxWidth: .infinity)
    }

    private func geometryDiagram(_ diagram: GeometryDiagram) -> some View {
        VStack(alignment: .leading, spacing: TKSpacing.sm) {
            GeometryDiagramView(
                diagram: diagram,
                showPointLabels: showGeometryPointLabels,
                showAngleNames: showGeometryAngleNames,
                showMeasurements: showGeometryMeasurements
            )
            .animation(.easeInOut(duration: 0.18), value: showGeometryPointLabels)
            .animation(.easeInOut(duration: 0.18), value: showGeometryAngleNames)
            .animation(.easeInOut(duration: 0.18), value: showGeometryMeasurements)

            HStack(spacing: TKSpacing.sm) {
                geometryLayerButton(
                    symbol: "A",
                    isOn: showGeometryPointLabels,
                    accessibilityLabel: "点の名前を表示"
                ) {
                    showGeometryPointLabels.toggle()
                }

                geometryLayerButton(
                    symbol: "∠",
                    isOn: showGeometryAngleNames,
                    accessibilityLabel: "角の名前を表示"
                ) {
                    showGeometryAngleNames.toggle()
                }

                geometryLayerButton(
                    symbol: "°",
                    isOn: showGeometryMeasurements,
                    accessibilityLabel: "角度を表示"
                ) {
                    showGeometryMeasurements.toggle()
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private func geometryLayerButton(
        symbol: String,
        isOn: Bool,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(isOn ? .white : TKColor.textSecondary)
                .frame(width: 38, height: 34)
                .background(isOn ? TKColor.accent : TKColor.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: TKRadius.small))
                .overlay(
                    RoundedRectangle(cornerRadius: TKRadius.small)
                        .stroke(isOn ? TKColor.accent.opacity(0.4) : TKColor.divider, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(isOn ? "オン" : "オフ")
    }

    private func progressLine(_ vm: ProblemViewModel) -> some View {
        HStack {
            Text("\(vm.stepIndex + 1) / \(vm.totalSteps)")
                .font(TKType.caption)
                .foregroundStyle(TKColor.textSecondary)
            Spacer()
            MathText(
                text: vm.problem.title,
                font: TKType.caption,
                scriptFont: .system(size: 9, weight: .semibold, design: .rounded),
                scriptOffset: 4
            )
                .foregroundStyle(TKColor.textTertiary)
        }
    }

    private func captionView(_ vm: ProblemViewModel) -> some View {
            MathText(
                text: vm.caption,
                font: TKType.subtitle,
                scriptFont: .system(size: 12, weight: .semibold, design: .rounded),
                scriptOffset: 6
            )
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
    private func inlineWorkPad(_ vm: ProblemViewModel) -> some View {
        if vm.problem.mode != .selfMade && vm.phase != .solved {
            VStack(alignment: .leading, spacing: TKSpacing.sm) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showWorkPad.toggle()
                    }
                } label: {
                    HStack(spacing: TKSpacing.sm) {
                        Label("書いて考えるメモ", systemImage: "pencil")
                            .font(TKType.caption)
                            .foregroundStyle(TKColor.textSecondary)
                        Spacer()
                        HStack(spacing: 5) {
                            Text(showWorkPad ? "閉じる" : "ひらく")
                            Image(systemName: showWorkPad ? "chevron.up" : "chevron.down")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .font(TKType.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, TKSpacing.sm)
                        .padding(.vertical, 7)
                        .background(TKColor.accent)
                        .clipShape(Capsule())
                    }
                }
                .buttonStyle(.plain)

                if showWorkPad {
                    DrawingCanvasView(
                        canvas: workCanvas,
                        toolPicker: workToolPicker,
                        becomesFirstResponder: false
                    )
                    .frame(height: horizontalSizeClass == .regular ? 180 : 132)
                    .background(TKColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: TKRadius.medium))
                    .overlay(
                        RoundedRectangle(cornerRadius: TKRadius.medium)
                            .stroke(TKColor.divider, lineWidth: 1.2)
                    )

                    HStack {
                        Button {
                            workCanvas.drawing = PKDrawing()
                        } label: {
                            Label("メモを消す", systemImage: "eraser")
                                .font(TKType.caption)
                                .foregroundStyle(TKColor.textSecondary)
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Text("ここは採点しません")
                            .font(TKType.caption)
                            .foregroundStyle(TKColor.textTertiary)
                    }
                }
            }
            .padding(TKSpacing.md)
            .background(TKColor.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: TKRadius.medium))
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
                    MathText(
                        text: vm.problem.hint,
                        font: TKType.body,
                        scriptFont: .system(size: 11, weight: .semibold, design: .rounded),
                        scriptOffset: 5
                    )
                        .foregroundStyle(TKColor.textSecondary)
                }
                .padding(TKSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(TKColor.warmSoft)
                .clipShape(RoundedRectangle(cornerRadius: TKRadius.medium))
                .id(Self.hintAnchorId)
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
            .frame(height: horizontalSizeClass == .regular ? 260 : 150)
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

            VStack(alignment: .leading, spacing: TKSpacing.sm) {
                HStack {
                    Text("手書き解答欄")
                        .font(TKType.caption)
                        .foregroundStyle(TKColor.textSecondary)
                    Spacer()
                    Text("ここだけ読み取ります")
                        .font(TKType.caption)
                        .foregroundStyle(TKColor.textTertiary)
                }

                DrawingCanvasView(
                    canvas: handwrittenAnswerCanvas,
                    toolPicker: handwrittenAnswerToolPicker,
                    becomesFirstResponder: false
                )
                .frame(height: horizontalSizeClass == .regular ? 150 : 104)
                .background(TKColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: TKRadius.medium))
                .overlay(
                    RoundedRectangle(cornerRadius: TKRadius.medium)
                        .stroke(selfMadeStroke(vm), lineWidth: 1.2)
                )

                HStack(spacing: TKSpacing.sm) {
                    Button {
                        handwrittenAnswerCanvas.drawing = PKDrawing()
                        vm.clearSelfMadeAnswerInput()
                    } label: {
                        Label("解答欄を消す", systemImage: "eraser")
                            .font(TKType.caption)
                            .foregroundStyle(TKColor.textSecondary)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    if isRecognizingHandwriting {
                        ProgressView()
                            .controlSize(.small)
                    }
                }

                if let message = vm.selfMadeRecognitionMessage {
                    Text(message)
                        .font(TKType.caption)
                        .foregroundStyle(recognitionMessageColor(message))
                        .fixedSize(horizontal: false, vertical: true)
                }

                PrimaryButton(
                    isRecognizingHandwriting ? "読み取り中" : "手書きを判定",
                    systemImage: "checkmark"
                ) {
                    submitHandwrittenAnswer(vm)
                }
                .disabled(isRecognizingHandwriting)
                .opacity(isRecognizingHandwriting ? 0.55 : 1)
            }
            .padding(.top, TKSpacing.sm)

            VStack(alignment: .leading, spacing: TKSpacing.xs) {
                Text("読み取り結果・キーボード入力")
                    .font(TKType.caption)
                    .foregroundStyle(TKColor.textSecondary)

                TextField(answerPlaceholder(for: vm.problem), text: Binding(
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

                Text(answerInputHelp(for: vm.problem))
                    .font(TKType.caption)
                    .foregroundStyle(TKColor.textTertiary)
            }

            if let feedback = vm.selfMadeFeedbackLabel {
                ChoiceButton(label: feedback,
                             state: vm.selfMadeFeedbackState) {}
                    .disabled(true)
            }

            PrimaryButton("入力で答え合わせ", systemImage: "keyboard") {
                vm.submitSelfMadeAnswer()
            }
            .disabled(!vm.canSubmitSelfMadeAnswer)
            .opacity(vm.canSubmitSelfMadeAnswer ? 1 : 0.45)
        }
    }

    @ViewBuilder
    private func footerActions(_ vm: ProblemViewModel, proxy: ScrollViewProxy) -> some View {
        switch vm.phase {
        case .revealed:
            PrimaryButton("次へ", systemImage: "arrow.right") { vm.advance() }
        case .wrongShown:
            VStack(spacing: TKSpacing.sm) {
                if vm.problem.mode == .selfMade {
                    HStack(spacing: TKSpacing.sm) {
                        PrimaryButton("入力を直す", style: .soft) { vm.retryStep() }
                        PrimaryButton("ヒント", style: .outline) {
                            showHintAndScroll(vm, proxy: proxy)
                        }
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
                        PrimaryButton("ヒント", style: .outline) {
                            showHintAndScroll(vm, proxy: proxy)
                        }
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
                    Label("ふくしゅう箱に入れる", systemImage: "tray.and.arrow.down")
                        .font(TKType.caption)
                        .foregroundStyle(TKColor.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, TKSpacing.sm)
                        .background(TKColor.accentSoft)
                        .clipShape(RoundedRectangle(cornerRadius: TKRadius.medium))
                }
                .buttonStyle(.plain)
            }
        case .prompt:
            EmptyView()
        }
    }

    private func toolBar(vm: ProblemViewModel, proxy: ScrollViewProxy) -> some View {
        HStack(spacing: TKSpacing.lg) {
            toolBtn("メモ",   icon: "square.and.pencil") { showMemo = true }
            toolBtn("ヒント", icon: "lightbulb") {
                showHintAndScroll(vm, proxy: proxy)
            }
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

    private func showHintAndScroll(_ vm: ProblemViewModel, proxy: ScrollViewProxy) {
        if !vm.showHint {
            withAnimation(.easeInOut(duration: 0.18)) {
                vm.showHint = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeInOut(duration: 0.28)) {
                proxy.scrollTo(Self.hintAnchorId, anchor: .center)
            }
        }
    }

    private func submitHandwrittenAnswer(_ vm: ProblemViewModel) {
        guard !isRecognizingHandwriting else { return }
        isRecognizingHandwriting = true
        defer { isRecognizingHandwriting = false }

        do {
            let recognized = try HandwritingAnswerService.shared
                .recognizeAnswer(from: handwrittenAnswerCanvas)
            vm.submitRecognizedSelfMadeAnswer(recognized)
        } catch let error as HandwritingRecognitionError {
            vm.showSelfMadeRecognitionError(error.studentMessage)
        } catch {
            vm.showSelfMadeRecognitionError("読み取りで問題が起きました。下の入力欄に答えを書いてください。")
        }
    }

    private func recognitionMessageColor(_ message: String) -> Color {
        message.hasPrefix("読み取り:") ? TKColor.textSecondary : TKColor.warm
    }

    private func answerPlaceholder(for problem: Problem) -> String {
        if problem.finalAnswer.contains("x") {
            return "例: x = 5"
        }
        if problem.finalAnswer.contains("°") {
            return "例: 60°"
        }
        return "例: \(problem.finalAnswer)"
    }

    private func answerInputHelp(for problem: Problem) -> String {
        if problem.finalAnswer.contains("x") {
            return "x = は書いても、書かなくてもOK"
        }
        if problem.finalAnswer.contains("°") {
            return "° や 度 は書いてもOK"
        }
        return "答えの値だけでもOK"
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
