// RunArchiveStore.swift — Persistent run history & achievement storage

import Foundation

// MARK: - Run Record

struct RunRecord: Codable {
    let id: UUID
    let date: Date
    let archetypeKind: String   // ArchetypeKind.rawValue
    let daysSurvived: Int
    let zombiesSlain: Int
    let survivorsMet: Int
    let victory: Bool

    init(chronicle: VigilChronicle, victory: Bool) {
        self.id            = UUID()
        self.date          = Date()
        self.archetypeKind = chronicle.archetype.kindling.rawValue
        self.daysSurvived  = chronicle.diurnalIndex
        self.zombiesSlain  = chronicle.revenantTally
        self.survivorsMet  = chronicle.wayfarerTally
        self.victory       = victory
    }
}

// MARK: - Run Archive Store

class RunArchiveStore {

    static let shared = RunArchiveStore()
    private let runsKey = "run_archive_v1"

    private(set) var runs: [RunRecord] = []

    private init() { load() }

    func save(record: RunRecord) {
        runs.insert(record, at: 0)
        if runs.count > 50 { runs = Array(runs.prefix(50)) }
        persist()
    }

    var bestDays: Int { runs.map(\.daysSurvived).max() ?? 0 }
    var totalRuns: Int { runs.count }
    var totalVictories: Int { runs.filter(\.victory).count }
    var totalZombies: Int { runs.map(\.zombiesSlain).reduce(0, +) }

    private func persist() {
        if let data = try? JSONEncoder().encode(runs) {
            UserDefaults.standard.set(data, forKey: runsKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: runsKey),
              let decoded = try? JSONDecoder().decode([RunRecord].self, from: data)
        else { return }
        runs = decoded
    }
}
