import SwiftUI
import CadenceCore

/// First-run goal picker. Choosing a goal drops the user onto a matching first sentence.
struct OnboardingView: View {
    let onFinish: (String?) -> Void

    private let goals: [(id: String, label: String)] = [
        ("everyday", "Everyday conversation"), ("work", "Work and meetings"),
        ("interview", "Job interviews"), ("exam", "An English exam"),
    ]

    var body: some View {
        ZStack {
            Tokens.ink.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                VoiceOrb(level: 0.25)
                    .frame(width: 240, height: 240)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                Spacer(minLength: 24)
                Text("Welcome to Cadence").font(.footnote).foregroundStyle(Tokens.paper.opacity(0.6))
                Text("What are you practicing for?")
                    .font(.system(size: 34, design: .serif)).foregroundStyle(Tokens.paper)
                    .padding(.top, 4)
                Text("Pick one. You can change it any time.")
                    .font(.callout).foregroundStyle(Tokens.paper.opacity(0.6)).padding(.top, 6)
                VStack(spacing: 10) {
                    ForEach(goals, id: \.id) { g in
                        Button { onFinish(g.id) } label: {
                            Text(g.label).font(.title3).frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 18).padding(.vertical, 16)
                                .background(Tokens.paper.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                                .foregroundStyle(Tokens.paper)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 20)
                Button("Skip for now") { onFinish(nil) }
                    .font(.callout).foregroundStyle(Tokens.paper.opacity(0.6)).padding(.top, 14)
            }
            .padding(20)
        }
        .preferredColorScheme(.dark)
    }
}
