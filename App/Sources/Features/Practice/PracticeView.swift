import SwiftUI
import CadenceCore

struct PracticeView: View {
    @StateObject private var vm = PracticeViewModel()
    @EnvironmentObject private var store: ProgressStore
    @AppStorage("goal") private var goal = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                categories
                Text(vm.reference)
                    .font(.system(size: 28, design: .serif))
                    .foregroundStyle(Tokens.paper)
                    .fixedSize(horizontal: false, vertical: true)
                orb
                controls
                message
                if case let .scored(result, _) = vm.state { ResultView(result: result) }
            }
            .padding(20)
        }
        .background(Tokens.ink.ignoresSafeArea())
        .onAppear { vm.store = store; if Sentences.categories.contains(goal) { vm.category = goal } }
        .onChange(of: goal) { _, g in if Sentences.categories.contains(g) { vm.category = g } }
    }

    private var header: some View {
        HStack {
            Text("Cadence").font(.system(size: 30, design: .serif)).foregroundStyle(Tokens.paper)
            Spacer()
            Text("\(vm.wordsRemaining) free words left today")
                .font(.footnote.monospacedDigit()).foregroundStyle(Tokens.paper.opacity(0.8))
                .padding(.horizontal, 10).padding(.vertical, 5)
                .overlay(Capsule().stroke(Tokens.paper.opacity(0.2)))
        }
    }

    private var categories: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(Sentences.categories, id: \.self) { c in
                    Button(c.capitalized) { vm.category = c }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(vm.category == c ? Tokens.paper : Tokens.paper.opacity(0.08), in: Capsule())
                        .foregroundStyle(vm.category == c ? Tokens.ink : Tokens.paper)
                }
            }
        }
    }

    @ViewBuilder private var orb: some View {
        if case let .scored(result, _) = vm.state {
            ScoreRing(score: Double(result.overall)).frame(width: 240, height: 240).frame(maxWidth: .infinity)
        } else {
            VoiceOrb(level: vm.level).frame(width: 240, height: 240).frame(maxWidth: .infinity)
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Text(vm.state == .listening ? "Listening…" : "Hold to speak")
                .font(.headline).foregroundStyle(.white)
                .padding(.horizontal, 24).padding(.vertical, 14)
                .background(Tokens.spectrum, in: RoundedRectangle(cornerRadius: 14))
                .scaleEffect(vm.state == .listening ? 0.97 : 1)
                .gesture(DragGesture(minimumDistance: 0)
                    .onChanged { _ in if vm.state != .listening { vm.pressDown() } }
                    .onEnded { _ in vm.pressUp() })
                .accessibilityAddTraits(.isButton)
                .accessibilityHint("Press and hold while you read the sentence aloud")
            Button("Next sentence") { vm.next() }
                .buttonStyle(.bordered).tint(Tokens.paper)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder private var message: some View {
        switch vm.state {
        case .capReached: Text("You've used today's 20 free words. Premium unlocks unlimited practice.")
        case .nothingHeard: Text("Didn't catch that. Try again a little closer to the mic.")
        case .failed(let m): Text(m)
        case .scored(_, true): Text("Some words weren't scored: daily free limit reached.")
        default: EmptyView()
        }
    }
}

struct ScoreRing: View {
    let score: Double
    var body: some View {
        ZStack {
            Circle().stroke(Tokens.paper.opacity(0.1), lineWidth: 22)
            Circle().trim(from: 0, to: Score.ringFraction(score))
                .stroke(Tokens.spectrum, style: StrokeStyle(lineWidth: 22, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(score))").font(.system(size: 56, weight: .semibold, design: .serif))
                .monospacedDigit().foregroundStyle(Tokens.paper)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Overall score \(Int(score)) out of 100")
    }
}

struct ResultView: View {
    let result: AttemptScore
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                stat("Overall", result.overall); stat("Accuracy", result.accuracy)
                stat("Complete", result.completeness); stat("Fluency", result.fluency)
            }
            FlowLayout(spacing: 8) {
                ForEach(Array(result.words.enumerated()), id: \.offset) { _, w in WordChip(word: w) }
            }
        }
    }
    private func stat(_ label: String, _ v: Int?) -> some View {
        VStack { Text(v.map(String.init) ?? "–").font(.system(size: 22, weight: .semibold, design: .serif)).monospacedDigit()
            Text(label).font(.caption).foregroundStyle(Tokens.paper.opacity(0.6)) }
            .frame(maxWidth: .infinity).padding(.vertical, 10)
            .background(Tokens.paper.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(Tokens.paper)
    }
}

struct WordChip: View {
    let word: WordResult
    var body: some View {
        VStack(spacing: 2) {
            Text(word.word).font(.title3)
            Text(word.heard == nil ? "missed" : (word.accuracy < 100 ? "heard “\(word.heard!)”" : "✓")).font(.caption2).opacity(0.7)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .foregroundStyle(Tokens.paper)
        .background(fill, in: RoundedRectangle(cornerRadius: 10))
        .opacity(ScoreBand(score: Double(word.accuracy)) == .dim ? 0.55 : 1)
        .onTapGesture { Speaker.say(word.word) }
        .accessibilityLabel("\(word.word), \(word.accuracy) percent")
        .accessibilityHint("Double tap to hear it spoken")
    }
    private var fill: Color {
        switch ScoreBand(score: Double(word.accuracy)) {
        case .dim: return Tokens.paper.opacity(0.06)
        case .warming: return Tokens.violet.opacity(0.25)
        case .bright: return Tokens.magenta.opacity(0.22)
        case .luminous: return Tokens.amber.opacity(0.18)
        }
    }
}

/// Minimal wrapping layout (iOS 16+).
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxW = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0, w: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x + sz.width > maxW { x = 0; y += rowH + spacing; rowH = 0 }
            x += sz.width + spacing; rowH = max(rowH, sz.height); w = max(w, x)
        }
        return CGSize(width: w, height: y + rowH)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowH: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x + sz.width > bounds.maxX { x = bounds.minX; y += rowH + spacing; rowH = 0 }
            s.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += sz.width + spacing; rowH = max(rowH, sz.height)
        }
    }
}
