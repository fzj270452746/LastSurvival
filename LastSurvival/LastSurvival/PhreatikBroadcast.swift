// PhreatikBroadcast.swift — Observer / Event Bus (low-frequency naming convention)
// Pattern: Observer
// New types: PhreatikBroadcast<T>, BroadcastReceptor, GrimwareSignal

import Foundation
import SpriteKit

// MARK: - BroadcastReceptor: observer interface for typed signals
protocol BroadcastReceptor: AnyObject {
    associatedtype SignalType
    func receive(signal: SignalType)
}

// MARK: - AnyBroadcastReceptor: type-erased wrapper for storing heterogeneous observers
private class AnyBroadcastReceptor<T> {
    private let _receive: (T) -> Void
    weak var identifier: AnyObject?

    init<R: BroadcastReceptor>(_ receptor: R) where R.SignalType == T {
        self.identifier = receptor
        self._receive   = { [weak receptor] signal in receptor?.receive(signal: signal) }
    }

    func relay(_ signal: T) {
        _receive(signal)
    }

    var isAlive: Bool { identifier != nil }
}

// MARK: - PhreatikBroadcast<T>: generic event emitter with weak-reference subscriber list
final class PhreatikBroadcast<T> {

    private var receptors: [AnyBroadcastReceptor<T>] = []

    // Subscribe a typed receptor — stored as weak reference, auto-evicted when deallocated
    func subscribe<R: BroadcastReceptor>(_ receptor: R) where R.SignalType == T {
        let wrapped = AnyBroadcastReceptor(receptor)
        receptors.append(wrapped)
    }

    // Remove a specific receptor by identity
    func unsubscribe(_ receptor: AnyObject) {
        receptors.removeAll { $0.identifier === receptor }
    }

    // Emit a signal to all living receptors, evicting stale entries
    func emit(_ signal: T) {
        receptors = receptors.filter(\.isAlive)
        receptors.forEach { $0.relay(signal) }
    }

    // Evict all dead receptors without emitting
    func pruneStale() {
        receptors = receptors.filter(\.isAlive)
    }

    // Current subscriber count (after eviction)
    var receptorCount: Int {
        pruneStale()
        return receptors.count
    }
}

// MARK: - GrimwareSignal: game-specific event vocabulary
enum GrimwareSignal {

    /// HP value changed: (newHP, maxHP)
    case vitalityAltered(Int, Int)

    /// Resource values changed — observer should re-read the grimoire
    case resourcesShifted

    /// A new day has begun: carries the new day index
    case solsticeAdvanced(Int)

    /// Weather conditions changed
    case etherChanged(EtherealClimate)

    /// Run concluded: true = victory, false = defeat
    case expeditionConcluded(Bool)

    /// Spin button interaction: true = spin started, false = spin ended
    case spinCycleToggled(Bool)

    /// Day settlement report ready
    case reckoningCompleted(DiurnalReckoning)
}

// MARK: - GrimwareBroadcaster: convenience alias for the game-specific emitter
typealias GrimwareBroadcaster = PhreatikBroadcast<GrimwareSignal>

// MARK: - VespersGrimoire extension: adds broadcast infrastructure
extension VespersGrimoire {

    // Lazily-created broadcaster attached to this grimoire instance via associated object
    var broadcaster: GrimwareBroadcaster {
        if let existing = objc_getAssociatedObject(self, &VespersGrimoire.broadcasterKey) as? GrimwareBroadcaster {
            return existing
        }
        let fresh = GrimwareBroadcaster()
        objc_setAssociatedObject(self, &VespersGrimoire.broadcasterKey, fresh, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return fresh
    }

    private static var broadcasterKey: UInt8 = 0

    // Emit after any state change — call these at mutation sites
    func broadcastVitality() {
        broadcaster.emit(.vitalityAltered(ichor, maxIchor))
    }

    func broadcastResources() {
        broadcaster.emit(.resourcesShifted)
    }

    func broadcastSolstice() {
        broadcaster.emit(.solsticeAdvanced(solsticeCount))
    }

    func broadcastEther() {
        broadcaster.emit(.etherChanged(etherClimate))
    }

    func broadcastConclusion(victory: Bool) {
        broadcaster.emit(.expeditionConcluded(victory))
    }

    func broadcastReckoning(_ ledger: DiurnalReckoning) {
        broadcaster.emit(.reckoningCompleted(ledger))
    }
}

// MARK: - TabulaVerdure extension: conforms to BroadcastReceptor
// The HUD subscribes to GrimwareSignal and refreshes automatically.
extension TabulaVerdure: BroadcastReceptor {
    typealias SignalType = GrimwareSignal

    /// Called by the broadcaster whenever game state changes
    func receive(signal: GrimwareSignal) {
        switch signal {
        case .vitalityAltered, .resourcesShifted, .solsticeAdvanced, .etherChanged:
            // All these require a HUD refresh; caller must supply the grimoire
            // TabulaVerdure stores a weak reference to its grimoire for self-refresh
            if let g = weakGrimoire { replenish(grimoire: g) }
        default:
            break
        }
    }

    // Attach a grimoire so the HUD can self-refresh on signals
    func bind(grimoire: VespersGrimoire) {
        weakGrimoire = grimoire
        grimoire.broadcaster.subscribe(self)
    }
}

// MARK: - TabulaVerdure weak grimoire storage (via associated object)
extension TabulaVerdure {
    fileprivate var weakGrimoire: VespersGrimoire? {
        get { objc_getAssociatedObject(self, &TabulaVerdure.grimoireKey) as? VespersGrimoire }
        set { objc_setAssociatedObject(self, &TabulaVerdure.grimoireKey, newValue, .OBJC_ASSOCIATION_ASSIGN) }
    }
    private static var grimoireKey: UInt8 = 0
}
