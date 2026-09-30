import SwiftUI
import CadenceCore

@main
struct CadenceApp: App {
    var body: some Scene {
        WindowGroup { RootView() }
    }
}

struct RootView: View {
    var body: some View { PracticeView() }
}
