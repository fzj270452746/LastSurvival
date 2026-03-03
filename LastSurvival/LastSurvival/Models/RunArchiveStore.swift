// RunArchiveStore.swift — Persistent run history & achievement storage (refactored)

import Foundation

// MARK: - PersistenceDriver: protocol abstracting UserDefaults storage
protocol PersistenceDriver {
    func load(key: String) -> Data?
    func save(data: Data, key: String)
}

// UserDefaultsDriver: default implementation backed by UserDefaults.standard
struct UserDefaultsDriver: PersistenceDriver {
    func load(key: String) -> Data? {
        UserDefaults.standard.data(forKey: key)
    }
    func save(data: Data, key: String) {
        UserDefaults.standard.set(data, forKey: key)
    }
}

// MARK: - CapacityPolicy: enforces a maximum number of stored records
struct CapacityPolicy {
    let maximumEntries: Int

    func enforce<T>(_ entries: [T]) -> [T] {
        guard entries.count > maximumEntries else { return entries }
        return Array(entries.prefix(maximumEntries))
    }
}

// MARK: - RunRecordCoder: serialisation helpers
enum RunRecordCoder {
    static func encode(_ records: [ExpeditionLog]) -> Data? {
        try? JSONEncoder().encode(records)
    }

    static func decode(from data: Data) -> [ExpeditionLog]? {
        try? JSONDecoder().decode([ExpeditionLog].self, from: data)
    }
}

// MARK: - RunStatistics: computed aggregates over a collection of runs
struct RunStatistics {
    let records: [ExpeditionLog]

    var bestDaysCount:  Int { records.map(\.solsticeEndured).max() ?? 0 }
    var totalRunCount:  Int { records.count }
    var victoryCount:   Int { records.filter(\.triumph).count }
    var zombieKillSum:  Int { records.map(\.spectersVanquished).reduce(0, +) }
}

// MARK: - ExpeditionLog (Run Record)
struct ExpeditionLog: Codable {
    let signum:               UUID
    let timestamp:            Date
    let vocationCaste:        String
    let solsticeEndured:      Int
    let spectersVanquished:   Int
    let pilgrimsEncountered:  Int
    let triumph:              Bool

    init(grimoire: VespersGrimoire, triumph: Bool) {
        self.signum               = UUID()
        self.timestamp            = Date()
        self.vocationCaste        = grimoire.vocationBlueprint.vocationCaste.rawValue
        self.solsticeEndured      = grimoire.solsticeCount
        self.spectersVanquished   = grimoire.specterTally
        self.pilgrimsEncountered  = grimoire.pilgrimTally
        self.triumph              = triumph
    }
}

// MARK: - AnnalsDepository (Run Archive Store)
class AnnalsDepository {

    static let shared = AnnalsDepository()

    private let storageKey     = "run_archive_v1"
    private let capacityPolicy = CapacityPolicy(maximumEntries: 50)
    private let storage:         PersistenceDriver

    private(set) var expeditions: [ExpeditionLog] = []

    // Designated init (testable via dependency injection)
    init(driver: PersistenceDriver = UserDefaultsDriver()) {
        self.storage = driver
        loadFromStorage()
    }

    // MARK: - Write
    func inscribe(log: ExpeditionLog) {
        // Prepend newest run, then apply capacity cap
        let candidate  = [log] + expeditions
        expeditions    = capacityPolicy.enforce(candidate)
        persistToStorage()
    }

    // MARK: - Statistics
    var statistics: RunStatistics { RunStatistics(records: expeditions) }

    var peakSolstice:     Int { statistics.bestDaysCount }
    var totalExpeditions: Int { statistics.totalRunCount }
    var totalTriumphs:    Int { statistics.victoryCount  }
    var totalSpecters:    Int { statistics.zombieKillSum }

    // MARK: - Private I/O

    private func loadFromStorage() {
        guard let data    = storage.load(key: storageKey),
              let decoded = RunRecordCoder.decode(from: data) else { return }
        expeditions = decoded
    }

    private func persistToStorage() {
        guard let encoded = RunRecordCoder.encode(expeditions) else { return }
        storage.save(data: encoded, key: storageKey)
    }

    // Legacy private names used during refactoring
    private func calcify()  { persistToStorage() }
    private func excavate() { loadFromStorage()   }
}

// MARK: - Backward-compat aliases

extension ExpeditionLog {
    init(chronicle: VespersGrimoire, victory: Bool) {
        self.init(grimoire: chronicle, triumph: victory)
    }
    var victory:       Bool   { triumph }
    var archetypeKind: String { vocationCaste }
    var daysSurvived:  Int    { solsticeEndured }
    var zombiesSlain:  Int    { spectersVanquished }
    var survivorsMet:  Int    { pilgrimsEncountered }
    var date:          Date   { timestamp }
}

extension AnnalsDepository {
    var totalRuns:      Int              { totalExpeditions }
    var bestDays:       Int              { peakSolstice }
    var totalVictories: Int              { totalTriumphs }
    var runs:           [ExpeditionLog]  { expeditions }
    func save(record: ExpeditionLog)     { inscribe(log: record) }
}

typealias RunRecord       = ExpeditionLog
typealias RunArchiveStore = AnnalsDepository

// MARK: - SedimentaryHoard: Repository protocol abstracting run-record storage
// Pattern: Repository
// Decouples consumers from the concrete AnnalsDepository, enabling future
// substitution (e.g. CloudKit-backed store, test doubles).
protocol SedimentaryHoard: AnyObject {
    var expeditions:      [ExpeditionLog] { get }
    var statistics:       RunStatistics   { get }
    var peakSolstice:     Int             { get }
    var totalExpeditions: Int             { get }
    var totalTriumphs:    Int             { get }
    var totalSpecters:    Int             { get }
    func inscribe(log: ExpeditionLog)
}

// Conform AnnalsDepository to the new protocol — zero-cost: all members already exist.
extension AnnalsDepository: SedimentaryHoard {}

// MARK: - CachingSedimentaryHoard: in-memory cache wrapper around AnnalsDepository
// Pattern: Repository (Caching Decorator)
// Wraps any SedimentaryHoard and keeps a warm in-memory cache of the expedition list,
// avoiding repeated UserDefaults decoding on every statistics query.
final class CachingSedimentaryHoard: SedimentaryHoard {

    private let inner:             AnnalsDepository
    private var cache:             [ExpeditionLog]?   // nil = cache cold
    private let cacheWriteThrough: Bool

    init(inner: AnnalsDepository = .shared, writeThrough: Bool = true) {
        self.inner             = inner
        self.cacheWriteThrough = writeThrough
    }

    // MARK: SedimentaryHoard conformance

    var expeditions: [ExpeditionLog] {
        if let cached = cache { return cached }
        let loaded = inner.expeditions
        cache = loaded
        return loaded
    }

    var statistics: RunStatistics { RunStatistics(records: expeditions) }

    func inscribe(log: ExpeditionLog) {
        inner.inscribe(log: log)
        if cacheWriteThrough {
            var updated = cache ?? []
            updated.insert(log, at: 0)
            cache = updated
        } else {
            cache = nil     // invalidate
        }
    }

    var peakSolstice:     Int { inner.peakSolstice     }
    var totalExpeditions: Int { expeditions.count       }
    var totalTriumphs:    Int { statistics.victoryCount }
    var totalSpecters:    Int { statistics.zombieKillSum }

    // MARK: Cache lifecycle

    /// Discard the cache so the next read reloads from persistent storage
    func invalidateCache() { cache = nil }

    /// Pre-load the cache from the underlying store
    func warmCache() { cache = inner.expeditions }

    // MARK: Shared accessor
    static let shared = CachingSedimentaryHoard()
}
