import SwiftUI
import CadenceCore

@main
struct CadenceApp: App {
    var body: some Scene {
        WindowGroup { RootView() }
    }
}

struct RootView: View {
    @State private var level = 0.3
    var body: some View {
        ZStack {
            Tokens.ink.ignoresSafeArea()
            VStack(spacing: 24) {
                VoiceOrb(level: level).frame(width: 260, height: 260)
                Text("Cadence").font(.system(size: 34, design: .serif)).foregroundStyle(.white)
                Slider(value: $level).padding(.horizontal, 40)
            }
        }
        .preferredColorScheme(.dark)
    }
}
