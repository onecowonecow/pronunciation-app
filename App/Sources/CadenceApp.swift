import SwiftUI

@main
struct CadenceApp: App {
    @StateObject private var store = ProgressStore()
    var body: some Scene {
        WindowGroup { RootView().environmentObject(store).preferredColorScheme(.dark) }
    }
}

struct RootView: View {
    @AppStorage("onboarded") private var onboarded = false
    @AppStorage("goal") private var goal = ""

    var body: some View {
        TabView {
            PracticeView().tabItem { Label("Practice", systemImage: "waveform") }
            HistoryView().tabItem { Label("History", systemImage: "chart.xyaxis.line") }
            WordBankView().tabItem { Label("Word Bank", systemImage: "text.book.closed") }
            WeekView().tabItem { Label("Week", systemImage: "flame") }
            SettingsView().tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(Tokens.magenta)
        .fullScreenCover(isPresented: Binding(get: { !onboarded }, set: { _ in })) {
            OnboardingView { picked in
                if let picked { goal = picked }
                onboarded = true
            }
        }
    }
}
