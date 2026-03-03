// AchievementRegistry.swift — Achievement definitions & unlock logic

import Foundation

// MARK: - Achievement Definition

struct Achievement: Codable {
    let id: String
    let title: String
    let description: String
    let icon: String          // emoji
    var isUnlocked: Bool
    var unlockedDate: Date?

    mutating func unlock() {
        guard !isUnlocked else { return }
        isUnlocked = true
        unlockedDate = Date()
    }
}

// MARK: - Registry

class AchievementRegistry {

    static let shared = AchievementRegistry()
    private let key = "achievements_v1"

    private(set) var all: [Achievement] = []

    private init() {
        loadOrSeed()
    }

    // Returns newly unlocked achievements after evaluating a finished run
    @discardableResult
    func evaluate(record: RunRecord) -> [Achievement] {
        let store = RunArchiveStore.shared
        var newlyUnlocked: [Achievement] = []

        check("first_run",       condition: store.totalRuns >= 1,                    newly: &newlyUnlocked)
        check("survivor_5",      condition: record.daysSurvived >= 5,                newly: &newlyUnlocked)
        check("survivor_10",     condition: record.daysSurvived >= 10,               newly: &newlyUnlocked)
        check("survivor_20",     condition: record.daysSurvived >= 20,               newly: &newlyUnlocked)
        check("victory",         condition: record.victory,                          newly: &newlyUnlocked)
        check("zombie_10",       condition: record.zombiesSlain >= 10,               newly: &newlyUnlocked)
        check("zombie_50",       condition: store.totalZombies >= 50,                newly: &newlyUnlocked)
        check("runs_5",          condition: store.totalRuns >= 5,                    newly: &newlyUnlocked)
        check("runs_10",         condition: store.totalRuns >= 10,                   newly: &newlyUnlocked)
        check("best_days_15",    condition: store.bestDays >= 15,                    newly: &newlyUnlocked)
        check("doctor_win",      condition: record.victory && record.archetypeKind == "chirurgeon", newly: &newlyUnlocked)
        check("soldier_win",     condition: record.victory && record.archetypeKind == "legionary",  newly: &newlyUnlocked)
        check("engineer_win",    condition: record.victory && record.archetypeKind == "artificer",  newly: &newlyUnlocked)

        persist()
        return newlyUnlocked
    }

    var unlockedCount: Int { all.filter(\.isUnlocked).count }

    // MARK: - Private

    private func check(_ id: String, condition: Bool, newly: inout [Achievement]) {
        guard condition else { return }
        guard let idx = all.firstIndex(where: { $0.id == id }), !all[idx].isUnlocked else { return }
        all[idx].unlock()
        newly.append(all[idx])
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(all) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func loadOrSeed() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([Achievement].self, from: data) {
            all = decoded
            return
        }
        all = Self.defaultAchievements
    }

    private static let defaultAchievements: [Achievement] = [
        Achievement(id: "first_run",    title: "First Steps",       description: "Complete your first run",              icon: "👣", isUnlocked: false),
        Achievement(id: "survivor_5",   title: "5-Day Survivor",    description: "Survive 5 days in one run",            icon: "🌅", isUnlocked: false),
        Achievement(id: "survivor_10",  title: "10-Day Veteran",    description: "Survive 10 days in one run",           icon: "🏕️", isUnlocked: false),
        Achievement(id: "survivor_20",  title: "20-Day Legend",     description: "Survive 20 days in one run",           icon: "🔥", isUnlocked: false),
        Achievement(id: "victory",      title: "Wasteland Victor",  description: "Survive all 30 days",                  icon: "🏆", isUnlocked: false),
        Achievement(id: "zombie_10",    title: "Zombie Slayer",     description: "Slay 10 zombies in one run",           icon: "🧟", isUnlocked: false),
        Achievement(id: "zombie_50",    title: "Undead Nemesis",    description: "Slay 50 zombies across all runs",      icon: "💀", isUnlocked: false),
        Achievement(id: "runs_5",       title: "Persistent",        description: "Play 5 runs",                          icon: "🔄", isUnlocked: false),
        Achievement(id: "runs_10",      title: "Obsessed",          description: "Play 10 runs",                         icon: "🎰", isUnlocked: false),
        Achievement(id: "best_days_15", title: "Halfway There",     description: "Reach day 15 in any run",              icon: "📅", isUnlocked: false),
        Achievement(id: "doctor_win",   title: "Healer's Triumph",  description: "Win as the Doctor",                    icon: "💉", isUnlocked: false),
        Achievement(id: "soldier_win",  title: "Iron Will",         description: "Win as the Soldier",                   icon: "⚔️", isUnlocked: false),
        Achievement(id: "engineer_win", title: "Mastermind",        description: "Win as the Engineer",                  icon: "⚙️", isUnlocked: false),
    ]
}
