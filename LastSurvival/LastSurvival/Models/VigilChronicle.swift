// VigilChronicle.swift — Core game state & data models

import Foundation

// MARK: - Glyph (Slot Icon Types)

enum GlyphVariant: CaseIterable {
    case provender   // food
    case aquifer     // water
    case armament    // weapon
    case revenant    // zombie
    case wayfarer    // survivor
}

// MARK: - Archetype (Character)

enum ArchetypeKind: String, CaseIterable {
    case chirurgeon  // doctor
    case legionary   // soldier
    case artificer   // engineer
}

struct SurvivorArchetype {
    let kindling: ArchetypeKind
    let epithet: String
    let portraitAsset: String
    let vitaBonus: Int
    let armamentBonus: Int
    let provenderBonus: Int
    let wayfarerBonus: Int
    let passiveDescription: String

    static let chirurgeon = SurvivorArchetype(
        kindling: .chirurgeon,
        epithet: "Doctor",
        portraitAsset: "char_doctor_avatar",
        vitaBonus: 2,
        armamentBonus: -1,
        provenderBonus: 0,
        wayfarerBonus: 0,
        passiveDescription: "Recover 1 HP every 3 days"
    )
    static let legionary = SurvivorArchetype(
        kindling: .legionary,
        epithet: "Soldier",
        portraitAsset: "char_soldier_avatar",
        vitaBonus: 0,
        armamentBonus: 2,
        provenderBonus: -1,
        wayfarerBonus: 0,
        passiveDescription: "Gain +1 weapon per 3 zombies slain"
    )
    static let artificer = SurvivorArchetype(
        kindling: .artificer,
        epithet: "Engineer",
        portraitAsset: "char_engineer_avatar",
        vitaBonus: 0,
        armamentBonus: 0,
        provenderBonus: 1,
        wayfarerBonus: 1,
        passiveDescription: "Gain +1 resource per 3 survivors"
    )

    static func fromKind(_ k: ArchetypeKind) -> SurvivorArchetype {
        switch k {
        case .chirurgeon: return .chirurgeon
        case .legionary:  return .legionary
        case .artificer:  return .artificer
        }
    }
}

// MARK: - Aether Condition (Weather)

enum AetherCondition: CaseIterable {
    case lucent      // sunny
    case deluge      // rain
    case scorching   // heat
    case murk        // fog
    case haboob      // sandstorm

    var iconAsset: String {
        switch self {
        case .lucent:    return "icon_weather_sunny"
        case .deluge:    return "icon_weather_rain"
        case .scorching: return "icon_weather_heat"
        case .murk:      return "icon_weather_fog"
        case .haboob:    return "icon_weather_sandstorm"
        }
    }

    var displayName: String {
        switch self {
        case .lucent:    return "Sunny"
        case .deluge:    return "Heavy Rain"
        case .scorching: return "Heat Wave"
        case .murk:      return "Dense Fog"
        case .haboob:    return "Sandstorm"
        }
    }

    // Returns adjusted weights [food, water, weapon, zombie, survivor]
    func adjustedWeights(base: [GlyphVariant: Int]) -> [GlyphVariant: Int] {
        var w = base
        switch self {
        case .lucent:
            break
        case .deluge:
            w[.aquifer]  = (w[.aquifer]  ?? 25) + 30
            w[.provender] = max(1, (w[.provender] ?? 25) - 10)
            w[.revenant]  = max(1, (w[.revenant]  ?? 20) - 10)
        case .scorching:
            w[.provender] = (w[.provender] ?? 25) + 10
        case .murk:
            w[.revenant]  = (w[.revenant]  ?? 20) + 25
            w[.armament]  = (w[.armament]  ?? 15) + 10
        case .haboob:
            w[.provender] = max(1, (w[.provender] ?? 25) - 10)
            w[.aquifer]   = max(1, (w[.aquifer]   ?? 25) - 10)
            w[.armament]  = max(1, (w[.armament]  ?? 15) - 10)
            w[.wayfarer]  = max(1, (w[.wayfarer]  ?? 15) - 10)
            w[.revenant]  = (w[.revenant]  ?? 20) + 20
        }
        return w
    }

    // Extra water consumption
    var aquiferDrainBonus: Int {
        return self == .scorching ? 1 : 0
    }
}

// MARK: - Foray Mode (Exploration)

enum ForayMode {
    case placid    // safe search
    case perilous  // dangerous explore
}

// MARK: - Vigil Chronicle (Game State)

class VigilChronicle {
    // Base weights
    static let baseWeights: [GlyphVariant: Int] = [
        .provender: 25,
        .aquifer:   25,
        .armament:  15,
        .revenant:  20,
        .wayfarer:  15
    ]

    var archetype: SurvivorArchetype
    var vitality: Int       // HP
    var provenderStock: Int // food
    var aquiferStock: Int   // water
    var armamentStock: Int  // weapon
    var wayfarerCount: Int  // survivors
    var diurnalIndex: Int   // current day
    var aetherCondition: AetherCondition
    var forayMode: ForayMode
    var revenantTally: Int  // total zombies killed (for soldier passive)
    var wayfarerTally: Int  // total survivors (for engineer passive)
    var isExpired: Bool     // dead
    var isVictorious: Bool  // won

    let maxVitality = 10
    let victoryThreshold = 30

    init(archetype: SurvivorArchetype) {
        self.archetype = archetype
        self.vitality = 5 + archetype.vitaBonus
        self.provenderStock = 2 + archetype.provenderBonus
        self.aquiferStock = 2
        self.armamentStock = max(0, 1 + archetype.armamentBonus)
        self.wayfarerCount = archetype.wayfarerBonus
        self.diurnalIndex = 1
        self.aetherCondition = .lucent
        self.forayMode = .placid
        self.revenantTally = 0
        self.wayfarerTally = archetype.wayfarerBonus
        self.isExpired = false
        self.isVictorious = false
    }

    // Roll new weather for the day
    func rollAetherCondition() {
        let all = AetherCondition.allCases
        aetherCondition = all.randomElement() ?? .lucent
    }

    // Compute current weights based on weather + foray mode
    func computeGlyphWeights() -> [GlyphVariant: Int] {
        var w = aetherCondition.adjustedWeights(base: VigilChronicle.baseWeights)
        if forayMode == .perilous {
            w[.revenant] = (w[.revenant] ?? 20) + 20
        }
        return w
    }

    // Spin the reels and return results
    func spinReels(count: Int = 3) -> [GlyphVariant] {
        let weights = computeGlyphWeights()
        var results: [GlyphVariant] = []
        for _ in 0..<count {
            results.append(weightedRandom(weights))
        }
        return results
    }

    private func weightedRandom(_ weights: [GlyphVariant: Int]) -> GlyphVariant {
        let total = weights.values.reduce(0, +)
        var roll = Int.random(in: 0..<total)
        for (glyph, w) in weights {
            roll -= w
            if roll < 0 { return glyph }
        }
        return .provender
    }

    // Settle a day's results; returns a log of events
    func settleDay(glyphs: [GlyphVariant]) -> DaySettlementLedger {
        var ledger = DaySettlementLedger()

        // Count glyphs
        var foodGained = 0, waterGained = 0, weaponGained = 0
        var zombieCount = 0, survivorCount = 0
        for g in glyphs {
            switch g {
            case .provender: foodGained += 1
            case .aquifer:   waterGained += 1
            case .armament:  weaponGained += 1
            case .revenant:  zombieCount += 1
            case .wayfarer:  survivorCount += 1
            }
        }

        // Perilous doubles resources
        if forayMode == .perilous {
            foodGained *= 2
            waterGained *= 2
            weaponGained *= 2
        }

        // Apply resources
        provenderStock += foodGained
        aquiferStock   += waterGained
        armamentStock  += weaponGained
        ledger.provenderGained = foodGained
        ledger.aquiferGained   = waterGained
        ledger.armamentGained  = weaponGained

        // Zombie combat
        let weaponsUsed = min(armamentStock, zombieCount)
        let undeflected = zombieCount - weaponsUsed
        armamentStock -= weaponsUsed
        revenantTally += zombieCount
        ledger.revenantCount = zombieCount
        ledger.vitaDamageFromRevenant = undeflected
        if undeflected > 0 {
            vitality -= undeflected
        }

        // Survivors
        wayfarerCount += survivorCount
        wayfarerTally += survivorCount
        ledger.wayfarerGained = survivorCount

        // Daily consumption
        let aquiferDrain = 1 + aetherCondition.aquiferDrainBonus
        let provenderDrain = 1

        if provenderStock >= provenderDrain {
            provenderStock -= provenderDrain
        } else {
            let deficit = provenderDrain - provenderStock
            provenderStock = 0
            vitality -= deficit
            ledger.vitaDamageFromHunger = deficit
        }

        if aquiferStock >= aquiferDrain {
            aquiferStock -= aquiferDrain
        } else {
            let deficit = aquiferDrain - aquiferStock
            aquiferStock = 0
            vitality -= deficit
            ledger.vitaDamageFromThirst = deficit
        }

        // Passive abilities
        applyPassives(ledger: &ledger)

        // Clamp vitality
        vitality = min(vitality, maxVitality)

        // Check death / victory
        if vitality <= 0 {
            vitality = 0
            isExpired = true
        } else if diurnalIndex >= victoryThreshold {
            isVictorious = true
        } else {
            diurnalIndex += 1
        }

        return ledger
    }

    private func applyPassives(ledger: inout DaySettlementLedger) {
        switch archetype.kindling {
        case .chirurgeon:
            if diurnalIndex % 3 == 0 {
                vitality = min(vitality + 1, maxVitality)
                ledger.passiveHeal = 1
            }
        case .legionary:
            let threshold = (revenantTally / 3)
            let prev = ((revenantTally - ledger.revenantCount) / 3)
            let bonus = threshold - prev
            if bonus > 0 {
                armamentStock += bonus
                ledger.passiveArmamentBonus = bonus
            }
        case .artificer:
            let threshold = (wayfarerTally / 3)
            let prev = ((wayfarerTally - ledger.wayfarerGained) / 3)
            let bonus = threshold - prev
            if bonus > 0 {
                provenderStock += bonus
                aquiferStock   += bonus
                armamentStock  += bonus
                ledger.passiveResourceBonus = bonus
            }
        }
    }
}

// MARK: - Day Settlement Ledger

struct DaySettlementLedger {
    var provenderGained = 0
    var aquiferGained   = 0
    var armamentGained  = 0
    var wayfarerGained  = 0
    var revenantCount   = 0
    var vitaDamageFromRevenant = 0
    var vitaDamageFromHunger   = 0
    var vitaDamageFromThirst   = 0
    var passiveHeal            = 0
    var passiveArmamentBonus   = 0
    var passiveResourceBonus   = 0

    var summaryLines: [String] {
        var lines: [String] = []
        if provenderGained > 0 { lines.append("+\(provenderGained) Food") }
        if aquiferGained   > 0 { lines.append("+\(aquiferGained) Water") }
        if armamentGained  > 0 { lines.append("+\(armamentGained) Weapon") }
        if wayfarerGained  > 0 { lines.append("+\(wayfarerGained) Survivor") }
        if revenantCount   > 0 { lines.append("\(revenantCount) Zombie(s) encountered") }
        if vitaDamageFromRevenant > 0 { lines.append("-\(vitaDamageFromRevenant) HP (zombie)") }
        if vitaDamageFromHunger   > 0 { lines.append("-\(vitaDamageFromHunger) HP (hunger)") }
        if vitaDamageFromThirst   > 0 { lines.append("-\(vitaDamageFromThirst) HP (thirst)") }
        if passiveHeal            > 0 { lines.append("+\(passiveHeal) HP (passive)") }
        if passiveArmamentBonus   > 0 { lines.append("+\(passiveArmamentBonus) Weapon (passive)") }
        if passiveResourceBonus   > 0 { lines.append("+\(passiveResourceBonus) Resources (passive)") }
        return lines
    }
}
