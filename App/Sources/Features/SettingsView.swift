import SwiftUI
import CadenceCore

struct SettingsView: View {
    @EnvironmentObject private var store: ProgressStore
    @AppStorage("reminder.enabled") private var reminderOn = false
    @AppStorage("reminder.minutes") private var reminderMinutes = 19 * 60 // 7:00 pm
    @State private var exportURL: URL?
    @State private var confirmDelete = false
    @State private var note = ""

    private var reminderTime: Binding<Date> {
        Binding(
            get: { Calendar.current.date(bySettingHour: reminderMinutes / 60, minute: reminderMinutes % 60, second: 0, of: Date()) ?? Date() },
            set: { d in
                let c = Calendar.current.dateComponents([.hour, .minute], from: d)
                reminderMinutes = (c.hour ?? 19) * 60 + (c.minute ?? 0)
                if reminderOn { Task { await schedule() } }
            })
    }

    var body: some View {
        Form {
            Section("Daily reminder") {
                Toggle("Remind me to practice", isOn: $reminderOn)
                    .onChange(of: reminderOn) { _, on in
                        if on { Task { await schedule() } } else { Reminders.disable(); note = "" }
                    }
                if reminderOn {
                    DatePicker("Time", selection: reminderTime, displayedComponents: .hourAndMinute)
                }
            }
            Section {
                if let exportURL {
                    ShareLink("Share export", item: exportURL)
                } else {
                    Button("Prepare export of my data") { exportURL = try? store.exportFile() }
                }
                Button("Delete all my data", role: .destructive) { confirmDelete = true }
            } header: { Text("Your data") } footer: {
                Text("Everything is stored on this device. Audio is never recorded or saved.")
            }
            if !note.isEmpty { Section { Text(note).font(.footnote) } }
        }
        .scrollContentBackground(.hidden)
        .background(Tokens.ink.ignoresSafeArea())
        .confirmationDialog("Delete all your history, Word Bank and XP from this device?",
                            isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete everything", role: .destructive) { store.deleteAll(); exportURL = nil; note = "All data deleted." }
        }
    }

    private func schedule() async {
        let ok = await Reminders.enable(hour: reminderMinutes / 60, minute: reminderMinutes % 60,
                                        streak: store.log.streak(), weakWords: store.log.bank.count)
        if !ok { reminderOn = false; note = "Notifications are turned off for Cadence. Enable them in Settings to get reminders." }
        else { note = "" }
    }
}
