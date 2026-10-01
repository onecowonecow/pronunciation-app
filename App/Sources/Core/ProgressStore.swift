import Foundation
import CadenceCore

/// Persists ProgressLog as JSON in Application Support. Shared by all tabs.
@MainActor
final class ProgressStore: ObservableObject {
    @Published private(set) var log: ProgressLog

    private let url: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("progress.json")
    }()

    init() {
        let data = try? Data(contentsOf: url)
        log = data.flatMap { try? JSONDecoder().decode(ProgressLog.self, from: $0) } ?? ProgressLog()
    }

    func record(_ result: AttemptScore, reference: String, scoredCount: Int) {
        log.record(result, reference: reference, scoredCount: scoredCount)
        if let data = try? JSONEncoder().encode(log) { try? data.write(to: url, options: .atomic) }
    }

    /// Pretty-printed JSON of everything stored, written to a temp file for sharing.
    func exportFile() throws -> URL {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        enc.dateEncodingStrategy = .iso8601
        let out = FileManager.default.temporaryDirectory.appendingPathComponent("cadence-data.json")
        try enc.encode(log).write(to: out, options: .atomic)
        return out
    }

    /// Removes all progress from memory and disk, plus the daily usage counters.
    func deleteAll() {
        log = ProgressLog()
        try? FileManager.default.removeItem(at: url)
        for key in UserDefaults.standard.dictionaryRepresentation().keys where key.hasPrefix("usage.") {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}
