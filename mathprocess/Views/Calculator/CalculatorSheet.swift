import SwiftUI

/// Tiny on-screen calculator. Intentionally minimal: 4 ops, ÷, =, C.
struct CalculatorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var display: String = "0"
    @State private var pending: Double? = nil
    @State private var op: Op? = nil
    @State private var resetOnNextDigit = true

    enum Op { case add, sub, mul, div }

    var body: some View {
        NavigationStack {
            VStack(spacing: TKSpacing.sm) {
                Text(display)
                    .font(.system(size: 44, weight: .semibold, design: .rounded).monospacedDigit())
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(TKSpacing.md)
                    .background(TKColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: TKRadius.medium))
                grid
                Spacer()
            }
            .padding(TKSpacing.md)
            .background(TKColor.background)
            .navigationTitle("計算機")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }

    private var grid: some View {
        VStack(spacing: TKSpacing.sm) {
            row(["C","±","%","÷"])
            row(["7","8","9","×"])
            row(["4","5","6","-"])
            row(["1","2","3","+"])
            row(["0","0",".","="])
        }
    }

    private func row(_ keys: [String]) -> some View {
        HStack(spacing: TKSpacing.sm) {
            ForEach(0..<keys.count, id: \.self) { i in
                let k = keys[i]
                Button {
                    handle(k)
                } label: {
                    Text(k)
                        .font(TKType.title)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(bg(k))
                        .foregroundStyle(fg(k))
                        .clipShape(RoundedRectangle(cornerRadius: TKRadius.medium))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func bg(_ k: String) -> Color {
        if "+-×÷=".contains(k) { return TKColor.accent }
        if k == "C" || k == "±" || k == "%" { return TKColor.surfaceElevated }
        return TKColor.surface
    }
    private func fg(_ k: String) -> Color {
        if "+-×÷=".contains(k) { return .white }
        return TKColor.textPrimary
    }

    private func handle(_ k: String) {
        switch k {
        case "C":
            display = "0"; pending = nil; op = nil; resetOnNextDigit = true
        case "±":
            if display.hasPrefix("-") { display.removeFirst() }
            else if display != "0"   { display = "-" + display }
        case "%":
            if let v = Double(display) { display = trim(v / 100) }
        case "+": setOp(.add)
        case "-": setOp(.sub)
        case "×": setOp(.mul)
        case "÷": setOp(.div)
        case "=": equals()
        case ".":
            if !display.contains(".") { display += "." }
        default:
            if resetOnNextDigit { display = k; resetOnNextDigit = false }
            else if display == "0" { display = k }
            else { display += k }
        }
    }

    private func setOp(_ next: Op) {
        if let p = pending, let o = op, !resetOnNextDigit,
           let cur = Double(display) {
            let r = apply(p, cur, o)
            display = trim(r); pending = r
        } else {
            pending = Double(display)
        }
        op = next
        resetOnNextDigit = true
    }

    private func equals() {
        guard let p = pending, let o = op, let cur = Double(display) else { return }
        display = trim(apply(p, cur, o))
        pending = nil; op = nil; resetOnNextDigit = true
    }

    private func apply(_ a: Double, _ b: Double, _ o: Op) -> Double {
        switch o {
        case .add: return a + b
        case .sub: return a - b
        case .mul: return a * b
        case .div: return b == 0 ? 0 : a / b
        }
    }

    private func trim(_ v: Double) -> String {
        if v == v.rounded() { return String(Int(v)) }
        return String(v)
    }
}
