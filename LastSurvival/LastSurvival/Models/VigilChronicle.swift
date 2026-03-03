// VigilChronicle.swift — Core game state & data models (refactored)

import Foundation

// MARK: - RuneSpecimen (Slot Icon Types)
enum RuneSpecimen: CaseIterable {
    case manna      // food
    case brine      // water
    case falchion   // weapon
    case specter    // zombie
    case pilgrim    // survivor
}

// MARK: - VocationCaste (Character Class)
enum VocationCaste: String, CaseIterable {
    case salver    // doctor
    case pikeman   // soldier
    case tinker    // engineer
}

// MARK: - WayfareBlueprint: character archetype definition
struct WayfareBlueprint {
    let vocationCaste:  VocationCaste
    let sobriquet:      String
    let effigyAsset:    String
    let ichorBonus:     Int
    let falchionBonus:  Int
    let mannaBonus:     Int
    let pilgrimBonus:   Int
    let latentAptitude: String

    static let medic = WayfareBlueprint(
        vocationCaste:  .salver,
        sobriquet:      "Doctor",
        effigyAsset:    "char_doctor_avatar",
        ichorBonus:     2,
        falchionBonus: -1,
        mannaBonus:     0,
        pilgrimBonus:   0,
        latentAptitude: "Recover 1 HP every 3 days"
    )
    static let combatant = WayfareBlueprint(
        vocationCaste:  .pikeman,
        sobriquet:      "Soldier",
        effigyAsset:    "char_soldier_avatar",
        ichorBonus:     0,
        falchionBonus:  2,
        mannaBonus:    -1,
        pilgrimBonus:   0,
        latentAptitude: "Gain +1 weapon per 3 zombies slain"
    )
    static let artisan = WayfareBlueprint(
        vocationCaste:  .tinker,
        sobriquet:      "Engineer",
        effigyAsset:    "char_engineer_avatar",
        ichorBonus:     0,
        falchionBonus:  0,
        mannaBonus:     1,
        pilgrimBonus:   1,
        latentAptitude: "Gain +1 resource per 3 survivors"
    )

    static func fromCaste(_ k: VocationCaste) -> WayfareBlueprint {
        switch k {
        case .salver:  return .medic
        case .pikeman: return .combatant
        case .tinker:  return .artisan
        }
    }
}

// MARK: - WeightTable: encapsulates weighted random sampling
struct WeightTable {
    private let table: [RuneSpecimen: Int]

    init(weights: [RuneSpecimen: Int]) {
        self.table = weights
    }

    // Draw a single specimen using weighted probability
    func draw() -> RuneSpecimen {
        let totalWeight = table.values.reduce(0, +)
        guard totalWeight > 0 else { return .manna }
        var cursor = Int.random(in: 0..<totalWeight)
        for (specimen, weight) in table {
            cursor -= weight
            if cursor < 0 { return specimen }
        }
        return .manna
    }

    // Draw multiple specimens
    func sample(count: Int) -> [RuneSpecimen] {
        (0..<count).map { _ in draw() }
    }

    // Return a new table with a delta patch applied (floor of 1 per entry)
    func applying(patch: [RuneSpecimen: Int]) -> WeightTable {
        var updated = table
        patch.forEach { specimen, delta in
            updated[specimen] = max(1, (updated[specimen] ?? 0) + delta)
        }
        return WeightTable(weights: updated)
    }

    // Expose raw table for legacy callers
    var rawWeights: [RuneSpecimen: Int] { table }
}

// MARK: - WeightModifier: describes how a context alters base weights
struct WeightModifier {
    let deltas: [RuneSpecimen: Int]
    static let identity = WeightModifier(deltas: [:])
}

// MARK: - EtherealClimate (Weather)
enum EtherealClimate: CaseIterable {
    case pellucid    // sunny
    case inundation  // rain
    case calefaction // heat
    case nebulosity  // fog
    case simoom      // sandstorm

    var sigillumAsset: String {
        switch self {
        case .pellucid:    return "icon_weather_sunny"
        case .inundation:  return "icon_weather_rain"
        case .calefaction: return "icon_weather_heat"
        case .nebulosity:  return "icon_weather_fog"
        case .simoom:      return "icon_weather_sandstorm"
        }
    }

    var appellative: String {
        switch self {
        case .pellucid:    return "Sunny"
        case .inundation:  return "Heavy Rain"
        case .calefaction: return "Heat Wave"
        case .nebulosity:  return "Dense Fog"
        case .simoom:      return "Sandstorm"
        }
    }

    // Weather-specific weight deltas, expressed as a pure modifier
    var weightModifier: WeightModifier {
        switch self {
        case .pellucid:
            return .identity
        case .inundation:
            return WeightModifier(deltas: [.brine: +30, .manna: -10, .specter: -10])
        case .calefaction:
            return WeightModifier(deltas: [.manna: +10])
        case .nebulosity:
            return WeightModifier(deltas: [.specter: +25, .falchion: +10])
        case .simoom:
            return WeightModifier(deltas: [
                .manna: -10, .brine: -10, .falchion: -10, .pilgrim: -10, .specter: +20
            ])
        }
    }

    // Legacy method — preserved for call-site compat
    func modulatedWeights(base: [RuneSpecimen: Int]) -> [RuneSpecimen: Int] {
        WeightTable(weights: base).applying(patch: weightModifier.deltas).rawWeights
    }

    var brineDrainBonus: Int { self == .calefaction ? 1 : 0 }
}

// MARK: - SortieRegime (Exploration Mode)
enum SortieRegime {
    case quiescent // safe search
    case fraught   // dangerous explore
}

// MARK: - PassiveEffectEngine: pure logic for character passive abilities
private enum PassiveEffectEngine {

    static func apply(
        caste:           VocationCaste,
        dayIndex:        Int,
        specterTotal:    Int,
        specterThisDay:  Int,
        pilgrimTotal:    Int,
        pilgrimThisDay:  Int,
        maxHP:           Int,
        ichor:           inout Int,
        falchionCache:   inout Int,
        mannaCache:      inout Int,
        brineCache:      inout Int,
        reckoning:       inout DiurnalReckoning
    ) {
        switch caste {

        case .salver:
            // Healer: restore 1 HP on every 3rd day
            guard dayIndex % 3 == 0 else { break }
            ichor = min(ichor + 1, maxHP)
            reckoning.latentMend = 1

        case .pikeman:
            // Soldier: earn a weapon for each new zombie-kill milestone (per 3)
            let milestonesBefore = (specterTotal - specterThisDay) / 3
            let milestonesAfter  = specterTotal / 3
            let earned           = milestonesAfter - milestonesBefore
            guard earned > 0 else { break }
            falchionCache += earned
            reckoning.latentFalchionBonus = earned

        case .tinker:
            // Engineer: earn resources for each new survivor milestone (per 3)
            let milestonesBefore = (pilgrimTotal - pilgrimThisDay) / 3
            let milestonesAfter  = pilgrimTotal / 3
            let earned           = milestonesAfter - milestonesBefore
            guard earned > 0 else { break }
            mannaCache    += earned
            brineCache    += earned
            falchionCache += earned
            reckoning.latentMannaBonus = earned
        }
    }
}

// MARK: - VespersGrimoire (Game State)
class VespersGrimoire {

    // Base reel weights before weather/mode adjustments
    static let runeBaseWeights: [RuneSpecimen: Int] = [
        .manna:    25,
        .brine:    25,
        .falchion: 15,
        .specter:  20,
        .pilgrim:  15
    ]

    var vocationBlueprint: WayfareBlueprint
    var ichor:         Int
    var mannaCache:    Int
    var brineCache:    Int
    var falchionCache: Int
    var pilgrimCount:  Int
    var solsticeCount: Int
    var etherClimate:  EtherealClimate
    var sortieRegime:  SortieRegime
    var specterTally:  Int
    var pilgrimTally:  Int
    var isDesiccated:  Bool
    var isTriumphant:  Bool

    let maxIchor:         Int = 10
    let triumphThreshold: Int = 30

    init(archetype: WayfareBlueprint) {
        vocationBlueprint = archetype
        ichor             = 5 + archetype.ichorBonus
        mannaCache        = 2 + archetype.mannaBonus
        brineCache        = 2
        falchionCache     = max(0, 1 + archetype.falchionBonus)
        pilgrimCount      = archetype.pilgrimBonus
        solsticeCount     = 1
        etherClimate      = .pellucid
        sortieRegime      = .quiescent
        specterTally      = 0
        pilgrimTally      = archetype.pilgrimBonus
        isDesiccated      = false
        isTriumphant      = false
    }

    // MARK: - Weather generation
    func augurClimate() {
        etherClimate = EtherealClimate.allCases.randomElement() ?? .pellucid
    }

    // MARK: - Weight computation
    func computeRuneWeights() -> [RuneSpecimen: Int] {
        var table = WeightTable(weights: VespersGrimoire.runeBaseWeights)
        table = table.applying(patch: etherClimate.weightModifier.deltas)
        if sortieRegime == .fraught {
            table = table.applying(patch: [.specter: +20])
        }
        return table.rawWeights
    }

    // MARK: - Reel casting
    func castLots(count: Int = 3) -> [RuneSpecimen] {
        WeightTable(weights: computeRuneWeights()).sample(count: count)
    }

    // MARK: - Day settlement pipeline
    func tallySolstice(specimens: [RuneSpecimen]) -> DiurnalReckoning {
        // Delegate to CalcinePipeline — all original logic is preserved inside the stages.
        // The direct imperative implementation below is kept as a commented reference.
        return CalcinePipeline.standard.settle(grimoire: self, specimens: specimens)
    }

    // MARK: - Original direct settlement logic (preserved for reference — now executed via pipeline stages)
    private func tallySolsticeDirect(specimens: [RuneSpecimen]) -> DiurnalReckoning {
        var ledger = DiurnalReckoning()

        // 1. Tally raw counts from reel results
        var rawManna = 0, rawBrine = 0, rawFalchion = 0, rawSpecter = 0, rawPilgrim = 0
        specimens.forEach { s in
            switch s {
            case .manna:    rawManna    += 1
            case .brine:    rawBrine    += 1
            case .falchion: rawFalchion += 1
            case .specter:  rawSpecter  += 1
            case .pilgrim:  rawPilgrim  += 1
            }
        }

        // 2. Fraught mode doubles resource yields
        let multiplier = sortieRegime == .fraught ? 2 : 1
        let gainManna    = rawManna    * multiplier
        let gainBrine    = rawBrine    * multiplier
        let gainFalchion = rawFalchion * multiplier

        // 3. Credit resources
        mannaCache    += gainManna
        brineCache    += gainBrine
        falchionCache += gainFalchion
        ledger.mannaHarvested    = gainManna
        ledger.brineHarvested    = gainBrine
        ledger.falchionHarvested = gainFalchion

        // 4. Resolve specter combat: weapons block zombies 1:1
        let blocked          = min(falchionCache, rawSpecter)
        let penetratingHits  = rawSpecter - blocked
        falchionCache       -= blocked
        specterTally        += rawSpecter
        ledger.specterCount       = rawSpecter
        ledger.ichorLostToSpecter = penetratingHits
        if penetratingHits > 0 { ichor -= penetratingHits }

        // 5. Pilgrims
        pilgrimCount += rawPilgrim
        pilgrimTally += rawPilgrim
        ledger.pilgrimHarvested = rawPilgrim

        // 6. Daily consumption: food (1/day) and water (1+bonus/day)
        let waterDemand = 1 + etherClimate.brineDrainBonus
        let foodDemand  = 1

        if mannaCache >= foodDemand {
            mannaCache -= foodDemand
        } else {
            let deficit = foodDemand - mannaCache
            mannaCache  = 0
            ichor      -= deficit
            ledger.ichorLostToHunger = deficit
        }

        if brineCache >= waterDemand {
            brineCache -= waterDemand
        } else {
            let deficit = waterDemand - brineCache
            brineCache  = 0
            ichor      -= deficit
            ledger.ichorLostToThirst = deficit
        }

        // 7. Character passive abilities
        PassiveEffectEngine.apply(
            caste:          vocationBlueprint.vocationCaste,
            dayIndex:       solsticeCount,
            specterTotal:   specterTally,
            specterThisDay: ledger.specterCount,
            pilgrimTotal:   pilgrimTally,
            pilgrimThisDay: ledger.pilgrimHarvested,
            maxHP:          maxIchor,
            ichor:          &ichor,
            falchionCache:  &falchionCache,
            mannaCache:     &mannaCache,
            brineCache:     &brineCache,
            reckoning:      &ledger
        )

        // 8. Clamp HP and check termination
        ichor = min(ichor, maxIchor)
        if ichor <= 0 {
            ichor = 0; isDesiccated = true
        } else if solsticeCount >= triumphThreshold {
            isTriumphant = true
        } else {
            solsticeCount += 1
        }

        return ledger
    }

    // Legacy private alias — kept so existing internal call sites compile
    private func stochasticSample(_ weights: [RuneSpecimen: Int]) -> RuneSpecimen {
        WeightTable(weights: weights).draw()
    }

    private func invokeLatencies(reckoning: inout DiurnalReckoning) {
        PassiveEffectEngine.apply(
            caste: vocationBlueprint.vocationCaste,
            dayIndex: solsticeCount,
            specterTotal: specterTally, specterThisDay: reckoning.specterCount,
            pilgrimTotal: pilgrimTally, pilgrimThisDay: reckoning.pilgrimHarvested,
            maxHP: maxIchor, ichor: &ichor, falchionCache: &falchionCache,
            mannaCache: &mannaCache, brineCache: &brineCache, reckoning: &reckoning
        )
    }
}

// MARK: - DiurnalReckoning (Day Settlement Report)
struct DiurnalReckoning {
    var mannaHarvested      = 0
    var brineHarvested      = 0
    var falchionHarvested   = 0
    var pilgrimHarvested    = 0
    var specterCount        = 0
    var ichorLostToSpecter  = 0
    var ichorLostToHunger   = 0
    var ichorLostToThirst   = 0
    var latentMend          = 0
    var latentFalchionBonus = 0
    var latentMannaBonus    = 0

    var compendiumLines: [String] {
        [
            mannaHarvested     > 0 ? "+\(mannaHarvested) Food"                      : nil,
            brineHarvested     > 0 ? "+\(brineHarvested) Water"                     : nil,
            falchionHarvested  > 0 ? "+\(falchionHarvested) Weapon"                 : nil,
            pilgrimHarvested   > 0 ? "+\(pilgrimHarvested) Survivor"                : nil,
            specterCount       > 0 ? "\(specterCount) Zombie(s) encountered"        : nil,
            ichorLostToSpecter > 0 ? "-\(ichorLostToSpecter) HP (zombie)"          : nil,
            ichorLostToHunger  > 0 ? "-\(ichorLostToHunger) HP (hunger)"           : nil,
            ichorLostToThirst  > 0 ? "-\(ichorLostToThirst) HP (thirst)"           : nil,
            latentMend         > 0 ? "+\(latentMend) HP (passive)"                  : nil,
            latentFalchionBonus > 0 ? "+\(latentFalchionBonus) Weapon (passive)"   : nil,
            latentMannaBonus   > 0 ? "+\(latentMannaBonus) Resources (passive)"     : nil
        ].compactMap { $0 }
    }

    var summaryLines: [String] { compendiumLines }
}

// MARK: - ReckoningContext: mutable context object passed through the CalcinePipeline
// Each AnvilStage receives this, mutates it, and passes it to the next stage.
struct ReckoningContext {
    var grimoire:       VespersGrimoire   // strong reference — stages mutate grimoire state directly
    var specimens:      [RuneSpecimen]    // reel results for this day
    var ledger:         DiurnalReckoning  // accumulated settlement report
    var multiplier:     Int               // 1 = quiescent, 2 = fraught
    var rawManna:       Int = 0
    var rawBrine:       Int = 0
    var rawFalchion:    Int = 0
    var rawSpecter:     Int = 0
    var rawPilgrim:     Int = 0

    init(grimoire: VespersGrimoire, specimens: [RuneSpecimen]) {
        self.grimoire   = grimoire
        self.specimens  = specimens
        self.ledger     = DiurnalReckoning()
        self.multiplier = grimoire.sortieRegime == .fraught ? 2 : 1
    }
}

// MARK: - AnvilStage: Pipeline stage protocol
// Pattern: Pipeline (Chain of Responsibility variant)
// Each stage handles exactly one concern in the day-settlement sequence.
protocol AnvilStage {
    func process(context: inout ReckoningContext)
}

// MARK: - Concrete AnvilStage implementations (low-frequency naming)

/// Stage 1 — Tally raw symbol counts from reel results
struct HarvestAnvilStage: AnvilStage {
    func process(context: inout ReckoningContext) {
        context.specimens.forEach { specimen in
            switch specimen {
            case .manna:    context.rawManna    += 1
            case .brine:    context.rawBrine    += 1
            case .falchion: context.rawFalchion += 1
            case .specter:  context.rawSpecter  += 1
            case .pilgrim:  context.rawPilgrim  += 1
            }
        }
        // Apply foray multiplier to resource yields
        let gainManna    = context.rawManna    * context.multiplier
        let gainBrine    = context.rawBrine    * context.multiplier
        let gainFalchion = context.rawFalchion * context.multiplier

        context.grimoire.mannaCache    += gainManna
        context.grimoire.brineCache    += gainBrine
        context.grimoire.falchionCache += gainFalchion

        context.ledger.mannaHarvested    = gainManna
        context.ledger.brineHarvested    = gainBrine
        context.ledger.falchionHarvested = gainFalchion
    }
}

/// Stage 2 — Resolve specter (zombie) combat: weapons block 1:1
struct SpecterAnvilStage: AnvilStage {
    func process(context: inout ReckoningContext) {
        let blocked         = min(context.grimoire.falchionCache, context.rawSpecter)
        let penetrating     = context.rawSpecter - blocked
        context.grimoire.falchionCache -= blocked
        context.grimoire.specterTally  += context.rawSpecter

        context.ledger.specterCount       = context.rawSpecter
        context.ledger.ichorLostToSpecter = penetrating
        if penetrating > 0 { context.grimoire.ichor -= penetrating }
    }
}

/// Stage 3 — Credit pilgrim (survivor) encounters
struct PilgrimAnvilStage: AnvilStage {
    func process(context: inout ReckoningContext) {
        context.grimoire.pilgrimCount += context.rawPilgrim
        context.grimoire.pilgrimTally += context.rawPilgrim
        context.ledger.pilgrimHarvested = context.rawPilgrim
    }
}

/// Stage 4 — Deduct daily consumption (food 1/day, water 1+heat/day)
struct ConsumptionAnvilStage: AnvilStage {
    func process(context: inout ReckoningContext) {
        let waterDemand = 1 + context.grimoire.etherClimate.brineDrainBonus
        let foodDemand  = 1

        if context.grimoire.mannaCache >= foodDemand {
            context.grimoire.mannaCache -= foodDemand
        } else {
            let deficit = foodDemand - context.grimoire.mannaCache
            context.grimoire.mannaCache  = 0
            context.grimoire.ichor      -= deficit
            context.ledger.ichorLostToHunger = deficit
        }

        if context.grimoire.brineCache >= waterDemand {
            context.grimoire.brineCache -= waterDemand
        } else {
            let deficit = waterDemand - context.grimoire.brineCache
            context.grimoire.brineCache  = 0
            context.grimoire.ichor      -= deficit
            context.ledger.ichorLostToThirst = deficit
        }
    }
}

/// Stage 5 — Trigger character passive abilities
struct LatencyAnvilStage: AnvilStage {
    func process(context: inout ReckoningContext) {
        PassiveEffectEngine.apply(
            caste:          context.grimoire.vocationBlueprint.vocationCaste,
            dayIndex:       context.grimoire.solsticeCount,
            specterTotal:   context.grimoire.specterTally,
            specterThisDay: context.ledger.specterCount,
            pilgrimTotal:   context.grimoire.pilgrimTally,
            pilgrimThisDay: context.ledger.pilgrimHarvested,
            maxHP:          context.grimoire.maxIchor,
            ichor:          &context.grimoire.ichor,
            falchionCache:  &context.grimoire.falchionCache,
            mannaCache:     &context.grimoire.mannaCache,
            brineCache:     &context.grimoire.brineCache,
            reckoning:      &context.ledger
        )
    }
}

/// Stage 6 — Clamp HP, check termination conditions, advance day counter
struct TerminusAnvilStage: AnvilStage {
    func process(context: inout ReckoningContext) {
        context.grimoire.ichor = min(context.grimoire.ichor, context.grimoire.maxIchor)
        if context.grimoire.ichor <= 0 {
            context.grimoire.ichor       = 0
            context.grimoire.isDesiccated = true
        } else if context.grimoire.solsticeCount >= context.grimoire.triumphThreshold {
            context.grimoire.isTriumphant = true
        } else {
            context.grimoire.solsticeCount += 1
        }
    }
}

// MARK: - CalcinePipeline: executes a sequence of AnvilStages
// Pattern: Pipeline
final class CalcinePipeline {
    private let stages: [any AnvilStage]

    // Standard pipeline with all six default stages in canonical order
    static let standard: CalcinePipeline = CalcinePipeline(stages: [
        HarvestAnvilStage(),
        SpecterAnvilStage(),
        PilgrimAnvilStage(),
        ConsumptionAnvilStage(),
        LatencyAnvilStage(),
        TerminusAnvilStage()
    ])

    init(stages: [any AnvilStage]) {
        self.stages = stages
    }

    /// Run the pipeline: mutates the context through each stage in sequence
    func run(context: inout ReckoningContext) {
        stages.forEach { $0.process(context: &context) }
    }

    /// Convenience: run and return the completed ledger
    func settle(grimoire: VespersGrimoire, specimens: [RuneSpecimen]) -> DiurnalReckoning {
        var ctx = ReckoningContext(grimoire: grimoire, specimens: specimens)
        run(context: &ctx)
        return ctx.ledger
    }
}

// MARK: - Backward-compat aliases
typealias GlyphVariant = RuneSpecimen
typealias ForayMode    = SortieRegime

extension SortieRegime {
    static var placid:   SortieRegime { .quiescent }
    static var perilous: SortieRegime { .fraught   }
}

extension WayfareBlueprint {
    var portraitAsset: String { effigyAsset }
}

extension VespersGrimoire {
    var forayMode: SortieRegime {
        get { sortieRegime }
        set { sortieRegime = newValue }
    }
    func rollAetherCondition()                                      { augurClimate() }
    func spinReels(count: Int) -> [RuneSpecimen]                    { castLots(count: count) }
    func settleDay(glyphs: [RuneSpecimen]) -> DiurnalReckoning      { tallySolstice(specimens: glyphs) }
    var isExpired:     Bool             { isDesiccated }
    var isVictorious:  Bool             { isTriumphant }
    var diurnalIndex:  Int              { solsticeCount }
    var archetype:     WayfareBlueprint { vocationBlueprint }
    var revenantTally: Int              { specterTally }
    var wayfarerTally: Int              { pilgrimTally }
    var vitality:      Int              { ichor }
}

typealias DaySettlementLedger = DiurnalReckoning
typealias VigilChronicle      = VespersGrimoire
