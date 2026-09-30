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
}
