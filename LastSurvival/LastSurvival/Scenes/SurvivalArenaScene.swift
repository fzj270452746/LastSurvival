// SurvivalArenaScene.swift — Main gameplay scene

import SpriteKit

class SurvivalArenaScene: SKScene {

    private let chronicle: VigilChronicle
    private var hudNode: ProvisionsManifestNode!
    private var reelNodes: [ReelAxleNode] = []
    private var spinBtn: ObsidianButtonNode!
    private var forayToggle: ForayToggleNode!
    private var ledgerPanel: LedgerPanelNode?
    private var isSpinning = false
    private var pendingGlyphs: [GlyphVariant] = []

    init(size: CGSize, chronicle: VigilChronicle) {
        self.chronicle = chronicle
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    override func didMove(to view: SKView) {
        backgroundColor = PaletteForge.obsidian
        chronicle.rollAetherCondition()
        buildUI()
    }

    private func buildUI() {
        let sc = size.adaptiveScale

        // Background
        let bg = SKSpriteNode(imageNamed: "bg_main")
        bg.size = size
        bg.position = CGPoint(x: size.width/2, y: size.height/2)
        bg.alpha = 0.30
        bg.zPosition = -1
        addChild(bg)

        // HUD — respect Dynamic Island / notch safe area
        let safeTop = view?.safeAreaInsets.top ?? 44
        let hudH = 110 * sc
        hudNode = ProvisionsManifestNode(sceneSize: size)
        hudNode.position = CGPoint(x: size.width/2, y: size.height - safeTop - hudH / 2)
        hudNode.zPosition = 5
        addChild(hudNode)
        hudNode.refresh(chronicle: chronicle)

        // Slot machine frame
        buildSlotMachine(sc: sc)

        // Foray toggle
        forayToggle = ForayToggleNode(sceneSize: size)
        forayToggle.position = CGPoint(x: size.width/2, y: size.height * 0.28)
        forayToggle.zPosition = 4
        forayToggle.onToggle = { [weak self] mode in
            self?.chronicle.forayMode = mode
        }
        addChild(forayToggle)

        // Spin button
        let btnW = 200 * sc
        let btnH = 54 * sc
        spinBtn = ObsidianButtonNode(
            size: CGSize(width: btnW, height: btnH),
            title: "SPIN",
            fillColor: PaletteForge.cinderGold,
            titleColor: PaletteForge.obsidian,
            cornerRadius: 27 * sc
        )
        spinBtn.position = CGPoint(x: size.width/2, y: size.height * 0.16)
        spinBtn.zPosition = 4
        spinBtn.onTap = { [weak self] in self?.beginSpin() }
        addChild(spinBtn)

        // Character portrait (top right) — aligned with HUD centre
        let portrait = SKSpriteNode(imageNamed: chronicle.archetype.portraitAsset)
        let pSize = 44 * sc
        portrait.size = CGSize(width: pSize, height: pSize)
        let safeTopPortrait = view?.safeAreaInsets.top ?? 44
        let hudH2 = 110 * sc
        portrait.position = CGPoint(x: size.width - pSize / 2 - 8 * sc, y: size.height - safeTopPortrait - hudH2 / 2)
        portrait.zPosition = 6
        addChild(portrait)

        // Menu button — below HUD, left-aligned
        let menuBtnW: CGFloat = 70 * sc
        let menuBtnH: CGFloat = 28 * sc
        let menuBtn = ObsidianButtonNode(
            size: CGSize(width: menuBtnW, height: menuBtnH),
            title: "MENU",
            fillColor: PaletteForge.slateGray,
            titleColor: PaletteForge.ashWhite,
            cornerRadius: 8 * sc
        )
        menuBtn.position = CGPoint(x: 14 * sc + menuBtnW / 2, y: size.height - safeTop - 20 * sc)
        menuBtn.zPosition = 6
        menuBtn.onTap = { [weak self] in self?.showAbandonConfirm() }
        addChild(menuBtn)
    }

    private func buildSlotMachine(sc: CGFloat) {
        let reelCount = 3
        let gap: CGFloat = 10 * sc
        let sidePad: CGFloat = 20 * sc
        let reelW = (size.width - sidePad * 2 - gap * CGFloat(reelCount - 1)) / CGFloat(reelCount)
        let reelH = reelW * 1.38
        let totalW = CGFloat(reelCount) * reelW + gap * CGFloat(reelCount - 1)
        let startX = (size.width - totalW) / 2 + reelW / 2
        let reelY = size.height * 0.52

        // Machine frame
        let frameW = totalW + 32 * sc
        let frameH = reelH + 40 * sc
        let machineFrame = PaletteForge.makeRoundedPanel(
            size: CGSize(width: frameW, height: frameH),
            cornerRadius: 18 * sc,
            fillColor: UIColor(red: 0.07, green: 0.08, blue: 0.12, alpha: 0.95),
            strokeColor: PaletteForge.cinderGold,
            lineWidth: 2.5
        )
        machineFrame.position = CGPoint(x: size.width/2, y: reelY)
        machineFrame.zPosition = 2
        addChild(machineFrame)

        // Glow line across center
        let glowLine = SKShapeNode()
        let glowPath = CGMutablePath()
        glowPath.move(to: CGPoint(x: -frameW/2 + 10 * sc, y: 0))
        glowPath.addLine(to: CGPoint(x: frameW/2 - 10 * sc, y: 0))
        glowLine.path = glowPath
        glowLine.strokeColor = PaletteForge.cinderGold.withAlphaComponent(0.25)
        glowLine.lineWidth = 2
        glowLine.zPosition = 3
        machineFrame.addChild(glowLine)

        // Reels
        reelNodes.removeAll()
        for i in 0..<reelCount {
            let reel = ReelAxleNode(size: CGSize(width: reelW, height: reelH))
            reel.position = CGPoint(x: startX + CGFloat(i) * (reelW + gap), y: reelY)
            reel.zPosition = 3
            addChild(reel)
            reelNodes.append(reel)
        }
    }

    // MARK: - Spin Logic

    private func beginSpin() {
        guard !isSpinning else { return }
        isSpinning = true
        spinBtn.setEnabled(false)
        forayToggle.setEnabled(false)

        let glyphs = chronicle.spinReels(count: reelNodes.count)
        pendingGlyphs = glyphs

        var completedCount = 0
        for (i, reel) in reelNodes.enumerated() {
            reel.spinTo(glyph: glyphs[i], delay: Double(i) * 0.18) { [weak self] in
                completedCount += 1
                if completedCount == self?.reelNodes.count {
                    self?.onAllReelsStopped()
                }
            }
        }
    }

    private func onAllReelsStopped() {
        // Flash result glyphs
        for reel in reelNodes {
            reel.run(SKAction.sequence([
                SKAction.scale(to: 1.06, duration: 0.1),
                SKAction.scale(to: 1.0, duration: 0.1)
            ]))
        }

        // Settle after brief pause
        run(SKAction.wait(forDuration: 0.5)) { [weak self] in
            self?.settleDay()
        }
    }

    private func settleDay() {
        let ledger = chronicle.settleDay(glyphs: pendingGlyphs)
        hudNode.refresh(chronicle: chronicle)

        showLedger(ledger: ledger)
    }

    private func showLedger(ledger: DaySettlementLedger) {
        let sc = size.adaptiveScale
        ledgerPanel?.removeFromParent()

        let panel = LedgerPanelNode(ledger: ledger, sceneSize: size)
        panel.position = CGPoint(x: size.width/2, y: size.height * 0.42)
        panel.zPosition = 10
        panel.onDismiss = { [weak self] in
            self?.ledgerPanel?.removeFromParent()
            self?.ledgerPanel = nil
            self?.afterLedger()
        }
        addChild(panel)
        ledgerPanel = panel
        _ = sc
    }

    private func afterLedger() {
        if chronicle.isExpired {
            goToEpitaph(victory: false)
        } else if chronicle.isVictorious {
            goToEpitaph(victory: true)
        } else {
            // New day: roll weather
            chronicle.rollAetherCondition()
            hudNode.refresh(chronicle: chronicle)
            isSpinning = false
            spinBtn.setEnabled(true)
            forayToggle.setEnabled(true)
        }
    }

    private func goToEpitaph(victory: Bool) {
        let scene = EpitaphScene(size: size, chronicle: chronicle, victory: victory)
        scene.scaleMode = scaleMode
        let trans = SKTransition.fade(withDuration: 0.6)
        view?.presentScene(scene, transition: trans)
    }

    // MARK: - Menu / Abandon

    private func showAbandonConfirm() {
        // Disable controls while overlay is shown
        spinBtn.setEnabled(false)
        forayToggle.setEnabled(false)

        let sc = size.adaptiveScale
        let overlay = SKNode()
        overlay.name = "abandonOverlay"
        overlay.zPosition = 30

        // Dimmer (blocks touches on underlying buttons via high zPosition)
        let dimmer = SKSpriteNode(color: UIColor(white: 0, alpha: 0.62), size: size)
        dimmer.position = CGPoint(x: size.width / 2, y: size.height / 2)
        dimmer.isUserInteractionEnabled = true
        overlay.addChild(dimmer)

        // Dialog panel
        let panelW: CGFloat = 270 * sc
        let panelH: CGFloat = 148 * sc
        let panel = PaletteForge.makeRoundedPanel(
            size: CGSize(width: panelW, height: panelH),
            cornerRadius: 16 * sc,
            fillColor: UIColor(red: 0.07, green: 0.07, blue: 0.12, alpha: 0.98),
            strokeColor: PaletteForge.cinderGold,
            lineWidth: 2
        )
        panel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.addChild(panel)

        let headLbl = PaletteForge.makeLabel(text: "ABANDON RUN?", fontSize: 16 * sc, color: PaletteForge.cinderGold, bold: true)
        headLbl.position = CGPoint(x: size.width / 2, y: size.height / 2 + panelH * 0.22)
        overlay.addChild(headLbl)

        let subLbl = PaletteForge.makeLabel(
            text: "Day \(chronicle.diurnalIndex) progress will be lost.",
            fontSize: 11 * sc,
            color: PaletteForge.ashWhite.withAlphaComponent(0.75)
        )
        subLbl.position = CGPoint(x: size.width / 2, y: size.height / 2 + panelH * 0.01)
        overlay.addChild(subLbl)

        let btnW: CGFloat = 108 * sc
        let btnH: CGFloat = 40 * sc
        let btnY = size.height / 2 - panelH * 0.28

        let abandonBtn = ObsidianButtonNode(
            size: CGSize(width: btnW, height: btnH),
            title: "ABANDON",
            fillColor: PaletteForge.bloodRed,
            titleColor: PaletteForge.ashWhite,
            cornerRadius: 10 * sc
        )
        abandonBtn.position = CGPoint(x: size.width / 2 - btnW / 2 - 6 * sc, y: btnY)
        abandonBtn.zPosition = 31
        abandonBtn.onTap = { [weak self] in self?.abandonRun() }
        overlay.addChild(abandonBtn)

        let cancelBtn = ObsidianButtonNode(
            size: CGSize(width: btnW, height: btnH),
            title: "CANCEL",
            fillColor: PaletteForge.slateGray,
            titleColor: PaletteForge.ashWhite,
            cornerRadius: 10 * sc
        )
        cancelBtn.position = CGPoint(x: size.width / 2 + btnW / 2 + 6 * sc, y: btnY)
        cancelBtn.zPosition = 31
        cancelBtn.onTap = { [weak self] in
            self?.childNode(withName: "abandonOverlay")?.removeFromParent()
            if !(self?.isSpinning ?? true) {
                self?.spinBtn.setEnabled(true)
                self?.forayToggle.setEnabled(true)
            }
        }
        overlay.addChild(cancelBtn)

        // Entrance
        overlay.setScale(0.92)
        overlay.alpha = 0
        addChild(overlay)
        overlay.run(SKAction.group([
            SKAction.fadeIn(withDuration: 0.18),
            SKAction.scale(to: 1.0, duration: 0.18)
        ]))
    }

    private func abandonRun() {
        let scene = TitleVaultScene(size: size)
        scene.scaleMode = scaleMode
        view?.presentScene(scene, transition: SKTransition.fade(withDuration: 0.4))
    }
}

// MARK: - ForayToggleNode

class ForayToggleNode: SKNode {

    var onToggle: ((ForayMode) -> Void)?
    private var currentMode: ForayMode = .placid
    private let placidBtn: ObsidianButtonNode
    private let perilousBtn: ObsidianButtonNode

    init(sceneSize: CGSize) {
        let sc = sceneSize.adaptiveScale
        let btnW = (sceneSize.width - 56 * sc) / 2
        let btnH = 40 * sc

        placidBtn = ObsidianButtonNode(
            size: CGSize(width: btnW, height: btnH),
            title: "SAFE SEARCH",
            fillColor: PaletteForge.jadeTeal,
            titleColor: PaletteForge.obsidian,
            cornerRadius: 10 * sc
        )
        perilousBtn = ObsidianButtonNode(
            size: CGSize(width: btnW, height: btnH),
            title: "DANGER EXPLORE",
            fillColor: PaletteForge.slateGray,
            titleColor: PaletteForge.ashWhite,
            cornerRadius: 10 * sc
        )

        super.init()

        let spacing = btnW / 2 + 6 * sc
        placidBtn.position = CGPoint(x: -spacing, y: 0)
        perilousBtn.position = CGPoint(x: spacing, y: 0)
        addChild(placidBtn)
        addChild(perilousBtn)

        placidBtn.onTap = { [weak self] in self?.select(.placid) }
        perilousBtn.onTap = { [weak self] in self?.select(.perilous) }
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    private func select(_ mode: ForayMode) {
        currentMode = mode
        placidBtn.alpha = mode == .placid ? 1.0 : 0.5
        perilousBtn.alpha = mode == .perilous ? 1.0 : 0.5
        onToggle?(mode)
    }

    func setEnabled(_ enabled: Bool) {
        placidBtn.setEnabled(enabled)
        perilousBtn.setEnabled(enabled)
    }
}

// MARK: - LedgerPanelNode

class LedgerPanelNode: SKNode {

    var onDismiss: (() -> Void)?

    init(ledger: DaySettlementLedger, sceneSize: CGSize) {
        super.init()
        let sc = sceneSize.adaptiveScale
        let lines = ledger.summaryLines
        let panelW = sceneSize.width * 0.78
        let lineH = 18 * sc
        let panelH = max(160 * sc, CGFloat(lines.count + 2) * lineH + 60 * sc)

        let bg = PaletteForge.makeRoundedPanel(
            size: CGSize(width: panelW, height: panelH),
            cornerRadius: 16 * sc,
            fillColor: UIColor(red: 0.07, green: 0.08, blue: 0.12, alpha: 0.97),
            strokeColor: PaletteForge.cinderGold,
            lineWidth: 2
        )
        addChild(bg)

        let titleLbl = PaletteForge.makeLabel(text: "DAY REPORT", fontSize: 14 * sc, color: PaletteForge.cinderGold, bold: true)
        titleLbl.position = CGPoint(x: 0, y: panelH/2 - 22 * sc)
        addChild(titleLbl)

        let startY = panelH/2 - 44 * sc
        for (i, line) in lines.enumerated() {
            let lbl = PaletteForge.makeLabel(text: line, fontSize: 12 * sc, color: PaletteForge.ashWhite)
            lbl.position = CGPoint(x: 0, y: startY - CGFloat(i) * lineH)
            addChild(lbl)
        }

        if lines.isEmpty {
            let emptyLbl = PaletteForge.makeLabel(text: "Nothing happened.", fontSize: 12 * sc, color: PaletteForge.ashWhite.withAlphaComponent(0.6))
            emptyLbl.position = CGPoint(x: 0, y: 0)
            addChild(emptyLbl)
        }

        let okBtn = ObsidianButtonNode(
            size: CGSize(width: 120 * sc, height: 38 * sc),
            title: "NEXT DAY",
            fillColor: PaletteForge.cinderGold,
            titleColor: PaletteForge.obsidian,
            cornerRadius: 10 * sc
        )
        okBtn.position = CGPoint(x: 0, y: -(panelH/2 - 26 * sc))
        okBtn.zPosition = 1
        okBtn.onTap = { [weak self] in
            self?.run(SKAction.group([
                SKAction.fadeOut(withDuration: 0.2),
                SKAction.scale(to: 0.85, duration: 0.2)
            ])) { self?.onDismiss?() }
        }
        addChild(okBtn)

        // Entrance
        setScale(0.85)
        alpha = 0
        run(SKAction.group([SKAction.fadeIn(withDuration: 0.22), SKAction.scale(to: 1.0, duration: 0.22)]))
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }
}
