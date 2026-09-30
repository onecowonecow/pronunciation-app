import SwiftUI
import Charts
import CadenceCore

private struct ScreenTitle: View {
    let text: String
    var body: some View { Text(text).font(.system(size: 28, design: .serif)).foregroundStyle(Tokens.paper) }
}

private struct EmptyNote: View {
    let text: String
    var body: some View {
        Text(text).font(.callout).foregroundStyle(Tokens.paper.opacity(0.6))
            .multilineTextAlignment(.center).frame(maxWidth: 280).padding(.vertical, 40).frame(maxWidth: .infinity)
    }
}

struct HistoryView: View {
    @EnvironmentObject private var store: ProgressStore
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ScreenTitle(text: "History")
                let recent = Array(store.log.history.suffix(30).enumerated())
                if recent.isEmpty {
                    EmptyNote(text: "No attempts yet. Read a sentence aloud and your scores will chart here.")
                } else {
                    Chart(recent, id: \.offset) { i, a in
                        LineMark(x: .value("Attempt", i), y: .value("Score", a.overall))
                            .foregroundStyle(Tokens.magenta).interpolationMethod(.monotone)
                    }
                    .chartYScale(domain: 0...100).frame(height: 180)
                    .accessibilityLabel("Score history chart")
                    ForEach(Array(store.log.history.suffix(20).reversed().enumerated()), id: \.offset) { _, a in
                        HStack(alignment: .firstTextBaseline) {
                            Text(a.reference).lineLimit(1).foregroundStyle(Tokens.paper)
                            Spacer(minLength: 16)
                            Text("\(a.overall)").font(.headline.monospacedDigit()).foregroundStyle(Tokens.paper)
                        }
                        Divider().overlay(Tokens.paper.opacity(0.1))
                    }
                }
            }.padding(20)
        }.background(Tokens.ink.ignoresSafeArea())
    }
}

struct WordBankView: View {
    @EnvironmentObject private var store: ProgressStore
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ScreenTitle(text: "Word Bank")
                if store.log.bank.isEmpty {
                    EmptyNote(text: "Nothing to review. Words you score under 80 collect here for practice.")
                } else {
                    ForEach(store.log.bankSorted, id: \.word) { item in
                        HStack(alignment: .firstTextBaseline) {
                            Text(item.word).font(.title3).foregroundStyle(Tokens.paper)
                                .onTapGesture { Speaker.say(item.word) }
                            Spacer()
                            Text("score \(item.entry.lastScore) · level \(item.entry.mastery)/5")
                                .font(.footnote.monospacedDigit()).foregroundStyle(Tokens.paper.opacity(0.7))
                        }
                        Divider().overlay(Tokens.paper.opacity(0.1))
                    }
                }
            }.padding(20)
        }.background(Tokens.ink.ignoresSafeArea())
    }
}

struct WeekView: View {
    @EnvironmentObject private var store: ProgressStore
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScreenTitle(text: "This week")
            Text("\(store.log.xp(inWeekOf: Date())) XP")
                .font(.system(size: 52, design: .serif)).monospacedDigit().foregroundStyle(Tokens.paper)
            Text("Streak: \(store.log.streak()) days").foregroundStyle(Tokens.paper.opacity(0.7))
            Text("The weekly leaderboard arrives with accounts.").font(.footnote)
                .foregroundStyle(Tokens.paper.opacity(0.5)).padding(.top, 8)
            Spacer()
        }
        .padding(20).frame(maxWidth: .infinity, alignment: .leading)
        .background(Tokens.ink.ignoresSafeArea())
    }
}
