// AchievementRegistry.swift — Achievement definitions & unlock logic (refactored)

import Foundation

// MARK: - Medallion (Achievement data)
struct Medallion: Codable {
    let signum:       String
    let epithet:      String
    let citation:     String
    let sigil:        String   // emoji icon
    var isBestowed:   Bool
    var bestowalDate: Date?

    mutating func bestow() {
        guard !isBestowed else { return }
        isBestowed   = true
        bestowalDate = Date()
    }
}

// MARK: - UnlockCondition: protocol-based unlock predicate
protocol UnlockCondition {
    var targetSignum: String { get }
    func evaluate(log: ExpeditionLog, archive: AnnalsDepository) -> Bool
}

// Concrete condition types — each encodes one achievement's logic

struct AnyRunCompletedCondition: UnlockCondition {
    let targetSignum = "first_run"
    func evaluate(log: ExpeditionLog, archive: AnnalsDepository) -> Bool {
        archive.totalExpeditions >= 1
    }
}

struct SurvivedDaysCondition: UnlockCondition {
    let targetSignum: String
    let threshold: Int
    func evaluate(log: ExpeditionLog, archive: AnnalsDepository) -> Bool {
        log.solsticeEndured >= threshold
    }
}

struct VictoryCondition: UnlockCondition {
    let targetSignum = "victory"
    func evaluate(log: ExpeditionLog, archive: AnnalsDepository) -> Bool {
        log.triumph
    }
}

struct SingleRunZombieCondition: UnlockCondition {
    let targetSignum: String
    let threshold: Int
    func evaluate(log: ExpeditionLog, archive: AnnalsDepository) -> Bool {
        log.spectersVanquished >= threshold
    }
}

struct CumulativeZombieCondition: UnlockCondition {
    let targetSignum: String
    let threshold: Int
    func evaluate(log: ExpeditionLog, archive: AnnalsDepository) -> Bool {
        archive.totalSpecters >= threshold
    }
}

struct TotalRunsCondition: UnlockCondition {
    let targetSignum: String
    let threshold: Int
    func evaluate(log: ExpeditionLog, archive: AnnalsDepository) -> Bool {
        archive.totalExpeditions >= threshold
    }
}

struct BestDaysCondition: UnlockCondition {
    let targetSignum: String
    let threshold: Int
    func evaluate(log: ExpeditionLog, archive: AnnalsDepository) -> Bool {
        archive.peakSolstice >= threshold
    }
}

struct ClassVictoryCondition: UnlockCondition {
    let targetSignum: String
    let casteRawValue: String
    func evaluate(log: ExpeditionLog, archive: AnnalsDepository) -> Bool {
        log.triumph && log.vocationCaste == casteRawValue
    }
}

// MARK: - MedallionCatalog: static dataset + condition registry
private enum MedallionCatalog {

    // All achievement definitions in declaration order
    static let allMedallions: [Medallion] = [
        Medallion(signum: "first_run",    epithet: "First Steps",      citation: "Complete your first run",         sigil: "👣", isBestowed: false),
        Medallion(signum: "survivor_5",   epithet: "5-Day Survivor",   citation: "Survive 5 days in one run",       sigil: "🌅", isBestowed: false),
        Medallion(signum: "survivor_10",  epithet: "10-Day Veteran",   citation: "Survive 10 days in one run",      sigil: "🏕️", isBestowed: false),
        Medallion(signum: "survivor_20",  epithet: "20-Day Legend",    citation: "Survive 20 days in one run",      sigil: "🔥", isBestowed: false),
        Medallion(signum: "victory",      epithet: "Wasteland Victor", citation: "Survive all 30 days",             sigil: "🏆", isBestowed: false),
        Medallion(signum: "zombie_10",    epithet: "Specter Slayer",   citation: "Slay 10 zombies in one run",      sigil: "🧟", isBestowed: false),
        Medallion(signum: "zombie_50",    epithet: "Undead Nemesis",   citation: "Slay 50 zombies across all runs", sigil: "💀", isBestowed: false),
        Medallion(signum: "runs_5",       epithet: "Persistent",       citation: "Play 5 runs",                     sigil: "🔄", isBestowed: false),
        Medallion(signum: "runs_10",      epithet: "Obsessed",         citation: "Play 10 runs",                    sigil: "🎰", isBestowed: false),
        Medallion(signum: "best_days_15", epithet: "Halfway There",    citation: "Reach day 15 in any run",         sigil: "📅", isBestowed: false),
        Medallion(signum: "doctor_win",   epithet: "Healer's Triumph", citation: "Win as the Doctor",               sigil: "💉", isBestowed: false),
        Medallion(signum: "soldier_win",  epithet: "Iron Will",        citation: "Win as the Soldier",              sigil: "⚔️", isBestowed: false),
        Medallion(signum: "engineer_win", epithet: "Mastermind",       citation: "Win as the Engineer",             sigil: "⚙️", isBestowed: false),
    ]

    // All conditions in the same order as allMedallions
    static let conditions: [any UnlockCondition] = [
        AnyRunCompletedCondition(),
        SurvivedDaysCondition(targetSignum: "survivor_5",   threshold: 5),
        SurvivedDaysCondition(targetSignum: "survivor_10",  threshold: 10),
        SurvivedDaysCondition(targetSignum: "survivor_20",  threshold: 20),
        VictoryCondition(),
        SingleRunZombieCondition(targetSignum: "zombie_10", threshold: 10),
        CumulativeZombieCondition(targetSignum: "zombie_50", threshold: 50),
        TotalRunsCondition(targetSignum: "runs_5",          threshold: 5),
        TotalRunsCondition(targetSignum: "runs_10",         threshold: 10),
        BestDaysCondition(targetSignum: "best_days_15",     threshold: 15),
        ClassVictoryCondition(targetSignum: "doctor_win",   casteRawValue: "salver"),
        ClassVictoryCondition(targetSignum: "soldier_win",  casteRawValue: "pikeman"),
        ClassVictoryCondition(targetSignum: "engineer_win", casteRawValue: "tinker"),
    ]
}

// MARK: - MedallionPersistence: handles storage operations for the compendium
private struct MedallionPersistence {
    let storageKey: String

    func persist(_ compendium: [Medallion]) {
        guard let encoded = try? JSONEncoder().encode(compendium) else { return }
        UserDefaults.standard.set(encoded, forKey: storageKey)
    }

    func restore() -> [Medallion]? {
        guard let data    = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([Medallion].self, from: data) else { return nil }
        return decoded
    }
}

// MARK: - MedallionCensus (Achievement Registry)
class MedallionCensus {

    static let shared = MedallionCensus()

    private let persistence = MedallionPersistence(storageKey: "achievements_v1")
    private(set) var compendium: [Medallion] = []

    private init() {
        compendium = persistence.restore() ?? MedallionCatalog.allMedallions
    }

    // MARK: - Evaluation

    @discardableResult
    func adjudicate(log: ExpeditionLog) -> [Medallion] {
        let archive       = AnnalsDepository.shared
        var freshUnlocks: [Medallion] = []

        // Evaluate every condition against the completed run
        MedallionCatalog.conditions.forEach { condition in
            guard condition.evaluate(log: log, archive: archive) else { return }
            attemptBestow(signum: condition.targetSignum, into: &freshUnlocks)
        }

        persistence.persist(compendium)
        return freshUnlocks
    }

    var bestowalCount: Int { compendium.filter(\.isBestowed).count }

    // MARK: - Private helpers

    private func attemptBestow(signum: String, into newlyUnlocked: inout [Medallion]) {
        guard let position = compendium.firstIndex(where: { $0.signum == signum }),
              !compendium[position].isBestowed else { return }
        compendium[position].bestow()
        newlyUnlocked.append(compendium[position])
    }

    // Legacy private name aliases
    private func scrutinize(_ signum: String, condition: Bool, newly: inout [Medallion]) {
        guard condition else { return }
        attemptBestow(signum: signum, into: &newly)
    }

    private func calcify()        { persistence.persist(compendium) }
    private func excavateOrSow()  { compendium = persistence.restore() ?? MedallionCatalog.allMedallions }
}

// MARK: - Backward-compat aliases

extension Medallion {
    var isUnlocked:   Bool    { isBestowed }
    var icon:         String  { sigil }
    var title:        String  { epithet }
    var description:  String  { citation }
    var unlockedDate: Date?   { bestowalDate }
}

extension MedallionCensus {
    var unlockedCount: Int          { bestowalCount }
    var all:           [Medallion]  { compendium }
    func evaluate(record: ExpeditionLog) -> [Medallion] { adjudicate(log: record) }
}

typealias Achievement         = Medallion
typealias AchievementRegistry = MedallionCensus
