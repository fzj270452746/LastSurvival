// EgressSediment.swift — Command Pattern for scene navigation
// Pattern: Command
// New types: EgressMandate (protocol), concrete egress structs, SceneWarden

import SpriteKit

// MARK: - EgressMandate: command interface for scene navigation
protocol EgressMandate {
    /// A human-readable label for logging and debugging
    var wardLabel: String { get }

    /// Execute the navigation command from the given scene
    func execute(from scene: SKScene)
}

// MARK: - Concrete Egress Commands (value types, low-frequency names)

/// Navigate to the character selection screen (→ VestibuleClaspScene)
struct VestibuleEgress: EgressMandate {
    let wardLabel = "vestibule_egress"

    func execute(from scene: SKScene) {
        let destination = VestibuleClaspScene(size: scene.size)
        destination.scaleMode = scene.scaleMode
        scene.view?.presentScene(destination,
            transition: SKTransition.push(with: .left, duration: 0.4))
    }
}

/// Navigate to the main gameplay arena
struct ArenaEgress: EgressMandate {
    let wardLabel = "arena_egress"
    let grimoire: VespersGrimoire

    func execute(from scene: SKScene) {
        let arena = SurvivalArenaScene(size: scene.size, chronicle: grimoire)
        arena.scaleMode = scene.scaleMode
        scene.view?.presentScene(arena,
            transition: SKTransition.push(with: .left, duration: 0.4))
    }
}

/// Navigate to the end-of-run epitaph screen
struct EpitaphEgress: EgressMandate {
    let wardLabel = "epitaph_egress"
    let chronicle: VespersGrimoire
    let victorious: Bool

    func execute(from scene: SKScene) {
        let endpoint = EpitaphScene(size: scene.size, chronicle: chronicle, victory: victorious)
        endpoint.scaleMode = scene.scaleMode
        scene.view?.presentScene(endpoint,
            transition: SKTransition.fade(withDuration: 0.6))
    }
}

/// Navigate back to the main menu
struct RetreatEgress: EgressMandate {
    let wardLabel = "retreat_egress"

    func execute(from scene: SKScene) {
        let menu = HarbingerDuskScene(size: scene.size)
        menu.scaleMode = scene.scaleMode
        scene.view?.presentScene(menu,
            transition: SKTransition.push(with: .right, duration: 0.35))
    }
}

/// Navigate to the run history screen
struct ChronolithEgress: EgressMandate {
    let wardLabel = "chronolith_egress"

    func execute(from scene: SKScene) {
        let hist = RunHistoryScene(size: scene.size)
        hist.scaleMode = scene.scaleMode
        scene.view?.presentScene(hist,
            transition: SKTransition.push(with: .left, duration: 0.35))
    }
}

/// Navigate to the achievements screen
struct PalimpsestEgress: EgressMandate {
    let wardLabel = "palimpsest_egress"

    func execute(from scene: SKScene) {
        let ach = AchievementScene(size: scene.size)
        ach.scaleMode = scene.scaleMode
        scene.view?.presentScene(ach,
            transition: SKTransition.push(with: .left, duration: 0.35))
    }
}

/// Navigate to the how-to-play screen
struct VademecumEgress: EgressMandate {
    let wardLabel = "vademecum_egress"

    func execute(from scene: SKScene) {
        let how = HowToPlayScene(size: scene.size)
        how.scaleMode = scene.scaleMode
        scene.view?.presentScene(how,
            transition: SKTransition.push(with: .left, duration: 0.35))
    }
}

// MARK: - SceneWarden: executes egress mandates, optionally logs a command history
class SceneWarden {

    // Optional command log — stores ward labels of executed mandates
    private(set) var commandLedger: [String] = []
    let enableLogging: Bool

    init(logging: Bool = false) {
        self.enableLogging = logging
    }

    /// Execute the given mandate from the specified scene
    func dispatch(_ mandate: EgressMandate, from scene: SKScene) {
        if enableLogging {
            commandLedger.append(mandate.wardLabel)
        }
        mandate.execute(from: scene)
    }

    /// Clear the command log
    func purgeLedger() {
        commandLedger.removeAll()
    }

    /// Replay the most recent mandate label for debugging
    var lastMandateLabel: String? { commandLedger.last }
}

// MARK: - SKScene convenience: attach a warden for one-shot dispatch
extension SKScene {

    /// Convenience: dispatch a mandate immediately without retaining a warden
    func dispatchEgress(_ mandate: EgressMandate) {
        SceneWarden().dispatch(mandate, from: self)
    }
}
