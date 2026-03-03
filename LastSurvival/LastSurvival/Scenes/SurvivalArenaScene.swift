// SurvivalArenaScene.swift — Main gameplay scene (refactored)

import SpriteKit

// MARK: - ArenaPhase: explicit game flow states
private enum ArenaPhase {
    case awaitingSpin
    case spinning
    case settling
    case showingLedger
    case gameOver
}

// MARK: - SurvivalArenaScene
class SurvivalArenaScene: SKScene {

    private let chronicle: VigilChronicle
    private var hudPanel:    ProvisionsManifestNode!
    private var reelColumns: [ReelAxleNode] = []
    fileprivate var spinButton:  ObsidianButtonNode!
    fileprivate var modeSwitch:  ForayToggleNode!
    private var reportPanel: LedgerPanelNode?

    private var currentPhase: ArenaPhase = .awaitingSpin
    private var pendingResults: [GlyphVariant] = []

    init(size: CGSize, chronicle: VigilChronicle) {
        self.chronicle = chronicle
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) not implemented") }

    override func didMove(to view: SKView) {
        backgroundColor = DesignToken.cosmicInk
        chronicle.rollAetherCondition()
        assembleInterface()
    }

    // MARK: - Interface assembly

    private func assembleInterface() {
        let sc = size.calibration
        mountSceneBackground(sc: sc)
        mountHUD(sc: sc)
        mountSlotMachine(sc: sc)
        mountModeToggle(sc: sc)
        mountSpinButton(sc: sc)
        mountMenuButton(sc: sc)
        mountPortrait(sc: sc)
    }

    private func mountSceneBackground(sc: CGFloat) {
        let wallpaper       = SKSpriteNode(imageNamed: "bg_main")
        wallpaper.size      = size
        wallpaper.position  = CGPoint(x: size.width / 2, y: size.height / 2)
        wallpaper.alpha     = 0.14
        wallpaper.zPosition = -1
        addChild(wallpaper)

        let tintOverlay       = SKShapeNode(rectOf: size)
        tintOverlay.position  = CGPoint(x: size.width / 2, y: size.height / 2)
        tintOverlay.fillColor = UIColor(red: 0.03, green: 0.02, blue: 0.14, alpha: 0.60)
        tintOverlay.strokeColor = .clear
        tintOverlay.zPosition = 0
        addChild(tintOverlay)
    }

    private func mountHUD(sc: CGFloat) {
        let safeTop = view?.safeAreaInsets.top ?? 44
        let hudH    = 114 * sc
        hudPanel    = ProvisionsManifestNode(sceneSize: size)
        hudPanel.position  = CGPoint(x: size.width / 2, y: size.height - safeTop - hudH / 2)
        hudPanel.zPosition = 5
        addChild(hudPanel)
        hudPanel.refresh(chronicle: chronicle)
    }

    private func mountSlotMachine(sc: CGFloat) {
        let reelCount  = 3
        let columnGap: CGFloat = 10 * sc
        let sidePadding: CGFloat = 18 * sc
        let columnW = (size.width - sidePadding * 2 - columnGap * CGFloat(reelCount - 1)) / CGFloat(reelCount)
        let columnH = columnW * 1.38
        let machineSpan = CGFloat(reelCount) * columnW + columnGap * CGFloat(reelCount - 1)
        let firstColumnX = (size.width - machineSpan) / 2 + columnW / 2
        let machineY = size.height * 0.52

        // Outer frame panel — cerulean border
        let frameW = machineSpan + 30 * sc
        let frameH = columnH  + 38 * sc
        let machineFrame = GeometryForge.panelNode(
            size:        CGSize(width: frameW, height: frameH),
            cutDepth:    14,
            fill:        UIColor(red: 0.04, green: 0.02, blue: 0.14, alpha: 0.97),
            stroke:      DesignToken.ceruleanVolt,
            strokeWidth: 3
        )
        machineFrame.glowWidth = 3
        machineFrame.position  = CGPoint(x: size.width / 2, y: machineY)
        machineFrame.zPosition = 2
        addChild(machineFrame)

        // Neon-pink corner brackets on frame
        GeometryForge.attachCornerBrackets(
            to:        machineFrame,
            covering:  CGSize(width: frameW, height: frameH),
            armLength: 16,
            tint:      DesignToken.radiantCrimson,
            thickness: 2
        )

        // Horizontal payline across center
        let paylinePath = CGMutablePath()
        paylinePath.move(to:    CGPoint(x: -frameW / 2 + 8 * sc, y: 0))
        paylinePath.addLine(to: CGPoint(x:  frameW / 2 - 8 * sc, y: 0))
        let paylineShape = SKShapeNode(path: paylinePath)
        paylineShape.strokeColor = DesignToken.radiantCrimson.withAlphaComponent(0.50)
        paylineShape.lineWidth   = 2
        paylineShape.zPosition   = 3
        machineFrame.addChild(paylineShape)

        // Reel columns
        reelColumns.removeAll()
        (0..<reelCount).forEach { columnIndex in
            let column      = ReelAxleNode(size: CGSize(width: columnW, height: columnH))
            column.position = CGPoint(x: firstColumnX + CGFloat(columnIndex) * (columnW + columnGap), y: machineY)
            column.zPosition = 3
            addChild(column)
            reelColumns.append(column)
        }
    }

    private func mountModeToggle(sc: CGFloat) {
        modeSwitch          = ForayToggleNode(sceneSize: size)
        modeSwitch.position = CGPoint(x: size.width / 2, y: size.height * 0.28)
        modeSwitch.zPosition = 4
        modeSwitch.onToggle  = { [weak self] mode in self?.chronicle.forayMode = mode }
        addChild(modeSwitch)
    }

    private func mountSpinButton(sc: CGFloat) {
        spinButton = ObsidianButtonNode(
            size:        CGSize(width: 210 * sc, height: 56 * sc),
            title:       "SPIN",
            fillColor:   DesignToken.radiantCrimson,
            titleColor:  DesignToken.frostSheen,
            cornerRadius: 28 * sc
        )
        spinButton.position  = CGPoint(x: size.width / 2, y: size.height * 0.16)
        spinButton.zPosition = 4
        spinButton.onTap     = { [weak self] in self?.executeSpinPhase() }
        addChild(spinButton)
    }

    private func mountMenuButton(sc: CGFloat) {
        let safeTop = view?.safeAreaInsets.top ?? 44
        let menuBtn = ObsidianButtonNode(
            size:        CGSize(width: 74 * sc, height: 30 * sc),
            title:       "MENU",
            fillColor:   DesignToken.violetShadow,
            titleColor:  DesignToken.frostSheen,
            cornerRadius: 8 * sc
        )
        menuBtn.position  = CGPoint(x: 14 * sc + 37 * sc, y: size.height - safeTop - 20 * sc)
        menuBtn.zPosition = 6
        menuBtn.onTap     = { [weak self] in self?.presentAbandonDialog() }
        addChild(menuBtn)
    }

    private func mountPortrait(sc: CGFloat) {
        let safeTop  = view?.safeAreaInsets.top ?? 44
        let hudH     = 114 * sc
        let iconSize = 44 * sc
        let portrait      = SKSpriteNode(imageNamed: chronicle.archetype.portraitAsset)
        portrait.size     = CGSize(width: iconSize, height: iconSize)
        portrait.position = CGPoint(x: size.width - iconSize / 2 - 8 * sc,
                                    y: size.height - safeTop - hudH / 2)
        portrait.zPosition = 6
        addChild(portrait)
    }

    // MARK: - Game flow phases

    private func executeSpinPhase() {
        guard currentPhase == .awaitingSpin else { return }
        advancePhase(to: .spinning)

        spinButton.setEnabled(false)
        modeSwitch.setEnabled(false)

        // Determine outcomes from the chronicle
        let outcomes = chronicle.spinReels(count: reelColumns.count)
        pendingResults = outcomes

        // Launch all reels with staggered delays
        var finishedCount = 0
        reelColumns.enumerated().forEach { index, reel in
            reel.spinTo(glyph: outcomes[index], delay: Double(index) * 0.18) { [weak self] in
                finishedCount += 1
                guard finishedCount == self?.reelColumns.count else { return }
                self?.processOutcomePhase()
            }
        }
    }

    private func processOutcomePhase() {
        advancePhase(to: .settling)

        // Brief bounce on all reels to signal completion
        reelColumns.forEach { column in
            column.run(SKAction.sequence([
                SKAction.scale(to: 1.06, duration: 0.09),
                SKAction.scale(to: 1.00, duration: 0.09)
            ]))
        }

        // Short delay before settling
        run(SKAction.wait(forDuration: 0.5)) { [weak self] in
            guard let self else { return }
            let dailyLedger = self.chronicle.settleDay(glyphs: self.pendingResults)
            self.hudPanel.refresh(chronicle: self.chronicle)
            self.presentReportPhase(ledger: dailyLedger)
        }
    }

    private func presentReportPhase(ledger: DaySettlementLedger) {
        advancePhase(to: .showingLedger)
        reportPanel?.removeFromParent()

        let report       = LedgerPanelNode(ledger: ledger, sceneSize: size)
        report.position  = CGPoint(x: size.width / 2, y: size.height * 0.42)
        report.zPosition = 10
        report.onDismiss = { [weak self] in
            self?.reportPanel?.removeFromParent()
            self?.reportPanel = nil
            self?.resolveNextCyclePhase()
        }
        addChild(report)
        reportPanel = report
    }

    private func resolveNextCyclePhase() {
        if chronicle.isExpired {
            advancePhase(to: .gameOver)
            navigateToEpitaph(victory: false)
        } else if chronicle.isVictorious {
            advancePhase(to: .gameOver)
            navigateToEpitaph(victory: true)
        } else {
            // New day: roll weather, refresh HUD, re-enable controls
            chronicle.rollAetherCondition()
            hudPanel.refresh(chronicle: chronicle)
            advancePhase(to: .awaitingSpin)
            spinButton.setEnabled(true)
            modeSwitch.setEnabled(true)
        }
    }

    private func advancePhase(to phase: ArenaPhase) {
        currentPhase = phase
    }

    // MARK: - Navigation

    private func navigateToEpitaph(victory: Bool) {
        let endpoint = EpitaphScene(size: size, chronicle: chronicle, victory: victory)
        endpoint.scaleMode = scaleMode
        view?.presentScene(endpoint, transition: SKTransition.fade(withDuration: 0.6))
    }

    // MARK: - Abandon dialog

    private func presentAbandonDialog() {
        spinButton.setEnabled(false)
        modeSwitch.setEnabled(false)
        AbandonFlowController.show(in: self, dayIndex: chronicle.diurnalIndex, scale: size.calibration,
            onAbort:  { [weak self] in self?.exitToMenu() },
            onCancel: { [weak self] in
                guard self?.currentPhase == .awaitingSpin else { return }
                self?.spinButton.setEnabled(true)
                self?.modeSwitch.setEnabled(true)
            }
        )
    }

    private func exitToMenu() {
        let menu = TitleVaultScene(size: size)
        menu.scaleMode = scaleMode
        view?.presentScene(menu, transition: SKTransition.fade(withDuration: 0.4))
    }

    // Legacy method aliases
    private func beginSpin()                                   { executeSpinPhase() }
    private func onAllReelsStopped()                           { processOutcomePhase() }
    private func settleDay()                                   { processOutcomePhase() }
    private func showLedger(ledger: DaySettlementLedger)       { presentReportPhase(ledger: ledger) }
    private func afterLedger()                                 { resolveNextCyclePhase() }
    private func goToEpitaph(victory: Bool)                    { navigateToEpitaph(victory: victory) }
    private func showAbandonConfirm()                          { presentAbandonDialog() }
    private func abandonRun()                                  { exitToMenu() }
}

// MARK: - AbandonFlowController: manages the exit-confirmation overlay
private enum AbandonFlowController {
    static func show(
        in scene: SKScene,
        dayIndex: Int,
        scale sc: CGFloat,
        onAbort:  @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        let overlayTag = "abandonFlow"
        guard scene.childNode(withName: overlayTag) == nil else { return }

        let container       = SKNode()
        container.name      = overlayTag
        container.zPosition = 30

        // Dim backdrop
        let dimRect = SKSpriteNode(
            color: UIColor(red: 0, green: 0, blue: 0.05, alpha: 0.72),
            size:  scene.size
        )
        dimRect.position                = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        dimRect.isUserInteractionEnabled = true
        container.addChild(dimRect)

        // Dialog panel
        let dialogW: CGFloat = 280 * sc
        let dialogH: CGFloat = 152 * sc
        let dialog = GeometryForge.panelNode(
            size:        CGSize(width: dialogW, height: dialogH),
            cutDepth:    12,
            fill:        UIColor(red: 0.06, green: 0.03, blue: 0.18, alpha: 0.98),
            stroke:      DesignToken.radiantCrimson,
            strokeWidth: 2.5
        )
        dialog.glowWidth = 2
        dialog.position  = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        container.addChild(dialog)

        // Title label
        let titleNode = TypographyScale.labelNode(
            text:   "ABORT RUN?",
            size:   17 * sc,
            tint:   DesignToken.radiantCrimson,
            weight: .headline
        )
        titleNode.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2 + dialogH * 0.22)
        container.addChild(titleNode)

        // Sub-message
        let subNode = TypographyScale.labelNode(
            text: "Day \(dayIndex) progress will be lost.",
            size: 11 * sc,
            tint: DesignToken.ashNebula
        )
        subNode.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2 + dialogH * 0.02)
        container.addChild(subNode)

        // Action buttons
        let buttonW: CGFloat = 112 * sc
        let buttonH: CGFloat = 42 * sc
        let buttonRowY = scene.size.height / 2 - dialogH * 0.28

        let abortBtn = ObsidianButtonNode(
            size:        CGSize(width: buttonW, height: buttonH),
            title:       "ABORT",
            fillColor:   DesignToken.vermillionAlert,
            titleColor:  DesignToken.frostSheen,
            cornerRadius: 10 * sc
        )
        abortBtn.position  = CGPoint(x: scene.size.width / 2 - buttonW / 2 - 6 * sc, y: buttonRowY)
        abortBtn.zPosition = 31
        abortBtn.onTap     = { onAbort() }
        container.addChild(abortBtn)

        let keepBtn = ObsidianButtonNode(
            size:        CGSize(width: buttonW, height: buttonH),
            title:       "CANCEL",
            fillColor:   DesignToken.violetShadow,
            titleColor:  DesignToken.frostSheen,
            cornerRadius: 10 * sc
        )
        keepBtn.position  = CGPoint(x: scene.size.width / 2 + buttonW / 2 + 6 * sc, y: buttonRowY)
        keepBtn.zPosition = 31
        keepBtn.onTap     = {
            scene.childNode(withName: overlayTag)?.removeFromParent()
            onCancel()
        }
        container.addChild(keepBtn)

        // Entrance animation
        container.setScale(0.90)
        container.alpha = 0
        scene.addChild(container)
        container.run(SKAction.group([
            SKAction.fadeIn(withDuration: 0.18),
            SKAction.scale(to: 1.0, duration: 0.18)
        ]))
    }
}

// MARK: - ForayToggleNode: two-segment mode selector
class ForayToggleNode: SKNode {

    var onToggle: ((ForayMode) -> Void)?
    private var activeMode: ForayMode = .placid
    private let safeButton:   ObsidianButtonNode
    private let dangerButton: ObsidianButtonNode

    init(sceneSize: CGSize) {
        let sc        = sceneSize.calibration
        let eachW     = (sceneSize.width - 56 * sc) / 2
        let eachH     = 42 * sc

        safeButton = ObsidianButtonNode(
            size:        CGSize(width: eachW, height: eachH),
            title:       "SAFE SEARCH",
            fillColor:   DesignToken.phosphorLime,
            titleColor:  DesignToken.cosmicInk,
            cornerRadius: 10 * sc
        )
        dangerButton = ObsidianButtonNode(
            size:        CGSize(width: eachW, height: eachH),
            title:       "DANGER EXPLORE",
            fillColor:   DesignToken.violetShadow,
            titleColor:  DesignToken.frostSheen,
            cornerRadius: 10 * sc
        )

        super.init()

        let offset = eachW / 2 + 6 * sc
        safeButton.position   = CGPoint(x: -offset, y: 0)
        dangerButton.position = CGPoint(x:  offset, y: 0)
        addChild(safeButton)
        addChild(dangerButton)

        safeButton.onTap   = { [weak self] in self?.applyMode(.placid)   }
        dangerButton.onTap = { [weak self] in self?.applyMode(.perilous) }
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) not implemented") }

    private func applyMode(_ mode: ForayMode) {
        activeMode = mode
        safeButton.alpha   = mode == .placid   ? 1.0 : 0.45
        dangerButton.alpha = mode == .perilous ? 1.0 : 0.45
        onToggle?(mode)
    }

    func setEnabled(_ enabled: Bool) {
        safeButton.setEnabled(enabled)
        dangerButton.setEnabled(enabled)
    }

    // Legacy alias
    private func select(_ mode: ForayMode) { applyMode(mode) }
}

// MARK: - LedgerPanelNode: day report summary overlay
class LedgerPanelNode: SKNode {

    var onDismiss: (() -> Void)?

    init(ledger: DaySettlementLedger, sceneSize: CGSize) {
        super.init()
        buildReport(ledger: ledger, sceneSize: sceneSize)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) not implemented") }

    private func buildReport(ledger: DaySettlementLedger, sceneSize: CGSize) {
        let sc      = sceneSize.calibration
        let lines   = ledger.summaryLines
        let panelW  = sceneSize.width * 0.80
        let rowH    = 18 * sc
        let minH    = 168 * sc
        let panelH  = max(minH, CGFloat(lines.count + 2) * rowH + 64 * sc)
        let panelSz = CGSize(width: panelW, height: panelH)

        // Background panel — cerulean border
        let panelBg = GeometryForge.panelNode(
            size:        panelSz,
            cutDepth:    12,
            fill:        UIColor(red: 0.05, green: 0.03, blue: 0.16, alpha: 0.97),
            stroke:      DesignToken.ceruleanVolt,
            strokeWidth: 2.5
        )
        panelBg.glowWidth = 2
        addChild(panelBg)

        // Corner brackets in crimson
        GeometryForge.attachCornerBrackets(
            to:        panelBg,
            covering:  panelSz,
            armLength: 12,
            tint:      DesignToken.radiantCrimson,
            thickness: 1.5
        )

        // "DAY REPORT" heading
        let heading = TypographyScale.labelNode(
            text:   "DAY REPORT",
            size:   15 * sc,
            tint:   DesignToken.radiantCrimson,
            weight: .headline
        )
        heading.position = CGPoint(x: 0, y: panelH / 2 - 22 * sc)
        addChild(heading)

        // Divider below heading
        let divider = GeometryForge.dividerLine(span: panelW * 0.8, tint: DesignToken.radiantCrimson, opacity: 0.35)
        divider.position = CGPoint(x: 0, y: panelH / 2 - 36 * sc)
        addChild(divider)

        // Summary lines or placeholder
        if lines.isEmpty {
            let emptyMsg = TypographyScale.labelNode(
                text: "Nothing happened.",
                size: 12 * sc,
                tint: DesignToken.ashNebula
            )
            emptyMsg.position = .zero
            addChild(emptyMsg)
        } else {
            let topLineY = panelH / 2 - 50 * sc
            lines.enumerated().forEach { index, lineText in
                let lineLabel = TypographyScale.labelNode(
                    text: lineText,
                    size: 12 * sc,
                    tint: DesignToken.frostSheen
                )
                lineLabel.position = CGPoint(x: 0, y: topLineY - CGFloat(index) * rowH)
                addChild(lineLabel)
            }
        }

        // NEXT DAY button
        let advanceBtn = ObsidianButtonNode(
            size:        CGSize(width: 130 * sc, height: 40 * sc),
            title:       "NEXT DAY",
            fillColor:   DesignToken.phosphorLime,
            titleColor:  DesignToken.cosmicInk,
            cornerRadius: 10 * sc
        )
        advanceBtn.position  = CGPoint(x: 0, y: -(panelH / 2 - 26 * sc))
        advanceBtn.zPosition = 1
        advanceBtn.onTap     = { [weak self] in
            self?.run(SKAction.group([
                SKAction.fadeOut(withDuration: 0.2),
                SKAction.scale(to: 0.88, duration: 0.2)
            ])) { self?.onDismiss?() }
        }
        addChild(advanceBtn)

        // Entrance animation
        setScale(0.82)
        alpha = 0
        run(AnimationBlueprint.modalEntrance(targetScale: 1.0, duration: 0.22))
    }
}

// MARK: - Backward-compat alias
typealias OublietteSpinScene = SurvivalArenaScene

extension SurvivalArenaScene {
    convenience init(size: CGSize, grimoire: VespersGrimoire) {
        self.init(size: size, chronicle: grimoire)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - State Pattern: PhaseObligation + PhaseSteward
// Formalises ArenaPhase transitions into discrete State objects.
// Each obligation encapsulates enter/exit side-effects for its specific phase.
// ─────────────────────────────────────────────────────────────────────────────

// MARK: - ArenaPhaseTag: lightweight identifier mirroring ArenaPhase
enum ArenaPhaseTag {
    case quiescent    // awaiting spin
    case vortex       // spinning
    case reckoning    // settling (bounce animation)
    case ledger       // showing day report
    case extinct      // game over
}

// MARK: - PhaseObligation: State protocol
// Pattern: State
protocol PhaseObligation: AnyObject {
    var tag: ArenaPhaseTag { get }
    func enter(arena: SurvivalArenaScene)
    func exit(arena: SurvivalArenaScene)
}

// MARK: - QuiescentObligation: awaitingSpin state
// Enables all interactive controls; player may spin.
final class QuiescentObligation: PhaseObligation {
    let tag: ArenaPhaseTag = .quiescent

    func enter(arena: SurvivalArenaScene) {
        arena.spinButton.setEnabled(true)
        arena.modeSwitch.setEnabled(true)
    }
    func exit(arena: SurvivalArenaScene) {
        arena.spinButton.setEnabled(false)
        arena.modeSwitch.setEnabled(false)
    }
}

// MARK: - VortexObligation: spinning state
// Controls are disabled; reels are in motion.
final class VortexObligation: PhaseObligation {
    let tag: ArenaPhaseTag = .vortex

    func enter(arena: SurvivalArenaScene) {
        // Controls already disabled by exit of QuiescentObligation
        // Optionally add a spinning indicator here in future
    }
    func exit(arena: SurvivalArenaScene) { }
}

// MARK: - ReckoningObligation: settling state
// Brief bounce feedback before ledger display.
final class ReckoningObligation: PhaseObligation {
    let tag: ArenaPhaseTag = .reckoning

    func enter(arena: SurvivalArenaScene) { }
    func exit(arena: SurvivalArenaScene)  { }
}

// MARK: - LedgerObligation: showingLedger state
// Day-report overlay is visible; waiting for player dismissal.
final class LedgerObligation: PhaseObligation {
    let tag: ArenaPhaseTag = .ledger

    func enter(arena: SurvivalArenaScene) { }
    func exit(arena: SurvivalArenaScene)  { }
}

// MARK: - ExtinctObligation: gameOver state
// No further interaction; scene will transition to EpitaphScene.
final class ExtinctObligation: PhaseObligation {
    let tag: ArenaPhaseTag = .extinct

    func enter(arena: SurvivalArenaScene) {
        // Disable everything to prevent accidental interaction during transition
        arena.spinButton.setEnabled(false)
        arena.modeSwitch.setEnabled(false)
    }
    func exit(arena: SurvivalArenaScene) { }
}

// MARK: - PhaseSteward: manages the current PhaseObligation and transitions
// Calling transition(to:arena:) exits the current state and enters the new one.
final class PhaseSteward {

    private(set) var current: any PhaseObligation

    init(initial: any PhaseObligation = QuiescentObligation()) {
        self.current = initial
    }

    /// Transition to a new obligation, invoking exit/enter hooks
    func transition(to next: any PhaseObligation, arena: SurvivalArenaScene) {
        guard current.tag != next.tag else { return }   // no-op on same-state transition
        current.exit(arena: arena)
        current = next
        current.enter(arena: arena)
    }

    var tag: ArenaPhaseTag { current.tag }
}

// MARK: - SurvivalArenaScene extension: steward integration
// Exposes a steward property via associated object and helpers to use it.
extension SurvivalArenaScene {

    var phaseSteward: PhaseSteward {
        if let existing = objc_getAssociatedObject(self, &SurvivalArenaScene.stewardKey) as? PhaseSteward {
            return existing
        }
        let fresh = PhaseSteward()
        objc_setAssociatedObject(self, &SurvivalArenaScene.stewardKey, fresh,
                                 .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return fresh
    }

    private static var stewardKey: UInt8 = 0

    /// Convenience: transition using the arena's steward
    func stewardTransition(to next: any PhaseObligation) {
        phaseSteward.transition(to: next, arena: self)
    }

    var stewardPhaseTag: ArenaPhaseTag { phaseSteward.tag }
}
