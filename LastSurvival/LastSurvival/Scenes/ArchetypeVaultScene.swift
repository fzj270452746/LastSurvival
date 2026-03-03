// ArchetypeVaultScene.swift — Character selection screen

import SpriteKit

class ArchetypeVaultScene: SKScene {

    private var selectedKind: ArchetypeKind = .chirurgeon
    private var cardNodes: [ArchetypeKind: SKNode] = [:]
    private var selectionRings: [ArchetypeKind: SKShapeNode] = [:]
    private var detailPanel: SKNode?
    private var cardFrames: [ArchetypeKind: CGRect] = [:]

    override func didMove(to view: SKView) {
        backgroundColor = PaletteForge.obsidian
        buildUI()
    }

    private func buildUI() {
        let sc = size.adaptiveScale

        // Background
        let bg = SKSpriteNode(imageNamed: "bg_main")
        bg.size = size
        bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
        bg.alpha = 0.25
        bg.zPosition = -1
        addChild(bg)

        // ── Header ──────────────────────────────────────────────
        // Use the real safe-area top inset so Dynamic Island / notch is never covered
        let safeTop = view?.safeAreaInsets.top ?? 44
        let headerH: CGFloat = 44 * sc
        let headerY = size.height - safeTop - headerH / 2

        let headerBg = SKShapeNode(rectOf: CGSize(width: size.width, height: headerH))
        headerBg.position = CGPoint(x: size.width / 2, y: headerY)
        headerBg.fillColor = UIColor(white: 0, alpha: 0.55)
        headerBg.strokeColor = .clear
        headerBg.zPosition = 1
        addChild(headerBg)

        // Back button – pinned to left, same Y as header centre
        let backW: CGFloat = 68 * sc
        let backH: CGFloat = 34 * sc
        let backBtn = ObsidianButtonNode(
            size: CGSize(width: backW, height: backH),
            title: "BACK",
            fillColor: PaletteForge.slateGray,
            titleColor: PaletteForge.ashWhite,
            cornerRadius: 8 * sc
        )
        backBtn.position = CGPoint(x: 16 * sc + backW / 2, y: headerY)
        backBtn.zPosition = 4
        backBtn.onTap = { [weak self] in self?.goBack() }
        addChild(backBtn)

        // Title – horizontally centred, same Y
        let titleLbl = PaletteForge.makeLabel(
            text: "CHOOSE YOUR SURVIVOR",
            fontSize: 14 * sc,
            color: PaletteForge.cinderGold,
            bold: true
        )
        titleLbl.position = CGPoint(x: size.width / 2, y: headerY)
        titleLbl.zPosition = 2
        addChild(titleLbl)

        // ── Cards ────────────────────────────────────────────────
        let archetypes: [ArchetypeKind] = [.chirurgeon, .legionary, .artificer]
        let gap: CGFloat = 10 * sc
        let sidePad: CGFloat = 14 * sc
        let cardW = (size.width - sidePad * 2 - gap * 2) / 3
        let cardH = cardW * 1.78
        let cardY = size.height * 0.555
        let startX = sidePad + cardW / 2

        for (i, kind) in archetypes.enumerated() {
            let arch = SurvivorArchetype.fromKind(kind)
            let x = startX + CGFloat(i) * (cardW + gap)
            let cardSize = CGSize(width: cardW, height: cardH)

            let (card, ring) = buildCard(archetype: arch, size: cardSize, scale: sc, selected: kind == selectedKind)
            card.position = CGPoint(x: x, y: cardY)
            card.zPosition = 2
            addChild(card)
            cardNodes[kind] = card
            selectionRings[kind] = ring

            // Hit-test rect in scene space — matches card position exactly (no moveBy)
            cardFrames[kind] = CGRect(
                x: x - cardW / 2,
                y: cardY - cardH / 2,
                width: cardW,
                height: cardH
            )

            // Fade-only entrance — no position shift keeps ring & frames valid
            card.alpha = 0
            card.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.12 * Double(i)),
                SKAction.fadeIn(withDuration: 0.3)
            ]))
        }

        buildDetailPanel(sc: sc)

        // ── Confirm button ───────────────────────────────────────
        let confirmBtn = ObsidianButtonNode(
            size: CGSize(width: 200 * sc, height: 50 * sc),
            title: "CONFIRM",
            fillColor: PaletteForge.cinderGold,
            titleColor: PaletteForge.obsidian,
            cornerRadius: 25 * sc
        )
        confirmBtn.position = CGPoint(x: size.width / 2, y: size.height * 0.09)
        confirmBtn.zPosition = 4
        confirmBtn.onTap = { [weak self] in self?.startGame() }
        addChild(confirmBtn)
    }

    // Returns (container, selectionRing) — ring is a child of the card
    private func buildCard(archetype: SurvivorArchetype, size: CGSize, scale sc: CGFloat, selected: Bool) -> (SKNode, SKShapeNode) {
        let container = SKNode()

        // Card background
        let bg = PaletteForge.makeRoundedPanel(
            size: size,
            cornerRadius: 14 * sc,
            fillColor: UIColor(red: 0.10, green: 0.11, blue: 0.16, alpha: 0.95),
            strokeColor: PaletteForge.slateGray.withAlphaComponent(0.5),
            lineWidth: 1
        )
        container.addChild(bg)

        // Selection ring — child of card so it moves with the card
        let ringRect = CGRect(x: -size.width / 2 - 3, y: -size.height / 2 - 3, width: size.width + 6, height: size.height + 6)
        let ringPath = UIBezierPath(roundedRect: ringRect, cornerRadius: 15 * sc)
        let ring = SKShapeNode(path: ringPath.cgPath)
        ring.strokeColor = PaletteForge.cinderGold
        ring.fillColor = .clear
        ring.lineWidth = 2.5
        ring.zPosition = 5
        ring.alpha = selected ? 1 : 0
        container.addChild(ring)

        // Portrait
        let portrait = SKSpriteNode(imageNamed: archetype.portraitAsset)
        portrait.size = CGSize(width: size.width * 0.76, height: size.width * 0.76)
        portrait.position = CGPoint(x: 0, y: size.height * 0.14)
        container.addChild(portrait)

        // Name
        let nameLbl = PaletteForge.makeLabel(
            text: archetype.epithet.uppercased(),
            fontSize: 10 * sc,
            color: PaletteForge.cinderGold,
            bold: true
        )
        nameLbl.position = CGPoint(x: 0, y: -size.height * 0.30)
        container.addChild(nameLbl)

        // Role tag
        let roles: [ArchetypeKind: String] = [.chirurgeon: "STABLE", .legionary: "COMBAT", .artificer: "GROWTH"]
        let roleTag = PaletteForge.makeLabel(
            text: roles[archetype.kindling] ?? "",
            fontSize: 8 * sc,
            color: PaletteForge.ashWhite.withAlphaComponent(0.45)
        )
        roleTag.position = CGPoint(x: 0, y: -size.height * 0.41)
        container.addChild(roleTag)

        return (container, ring)
    }

    private func buildDetailPanel(sc: CGFloat) {
        detailPanel?.removeFromParent()
        let arch = SurvivorArchetype.fromKind(selectedKind)
        let panelW = size.width - 28 * sc
        let panelH: CGFloat = 108 * sc

        let panel = PaletteForge.makeRoundedPanel(
            size: CGSize(width: panelW, height: panelH),
            cornerRadius: 14 * sc,
            fillColor: PaletteForge.panelBg,
            strokeColor: PaletteForge.cinderGold.withAlphaComponent(0.4),
            lineWidth: 1
        )
        panel.position = CGPoint(x: size.width / 2, y: size.height * 0.225)
        panel.zPosition = 3
        addChild(panel)
        detailPanel = panel

        let stats: [(String, Int)] = [
            ("HP",     5 + arch.vitaBonus),
            ("Food",   2 + arch.provenderBonus),
            ("Water",  2),
            ("Weapon", max(0, 1 + arch.armamentBonus))
        ]
        let colW = panelW / 4
        for (i, (name, val)) in stats.enumerated() {
            let x = -panelW / 2 + colW * (CGFloat(i) + 0.5)
            let valLbl = PaletteForge.makeLabel(text: "\(val)", fontSize: 20 * sc, color: PaletteForge.cinderGold, bold: true)
            valLbl.position = CGPoint(x: x, y: panelH * 0.14)
            panel.addChild(valLbl)
            let nameLbl = PaletteForge.makeLabel(text: name, fontSize: 9 * sc, color: PaletteForge.ashWhite.withAlphaComponent(0.65))
            nameLbl.position = CGPoint(x: x, y: -panelH * 0.09)
            panel.addChild(nameLbl)
        }

        let passiveLbl = PaletteForge.makeLabel(text: "Passive: \(arch.passiveDescription)", fontSize: 10 * sc, color: PaletteForge.jadeTeal)
        passiveLbl.position = CGPoint(x: 0, y: -panelH * 0.33)
        passiveLbl.numberOfLines = 2
        passiveLbl.preferredMaxLayoutWidth = panelW - 20 * sc
        panel.addChild(passiveLbl)
    }

    // ── Touch handling ───────────────────────────────────────────
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)
        for (kind, frame) in cardFrames {
            if frame.contains(loc) {
                selectCard(kind)
                break
            }
        }
    }

    private func selectCard(_ kind: ArchetypeKind) {
        guard kind != selectedKind else { return }
        // Hide old ring
        selectionRings[selectedKind]?.alpha = 0
        selectionRings[selectedKind]?.removeAllActions()

        selectedKind = kind

        // Show new ring with pulse
        if let ring = selectionRings[kind] {
            ring.alpha = 1
            ring.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.45, duration: 0.65),
                SKAction.fadeAlpha(to: 1.0, duration: 0.65)
            ])))
        }

        // Bounce card
        cardNodes[kind]?.run(SKAction.sequence([
            SKAction.scale(to: 0.93, duration: 0.07),
            SKAction.scale(to: 1.0, duration: 0.07)
        ]))

        buildDetailPanel(sc: size.adaptiveScale)
    }

    private func startGame() {
        let arch = SurvivorArchetype.fromKind(selectedKind)
        let chronicle = VigilChronicle(archetype: arch)
        let arena = SurvivalArenaScene(size: size, chronicle: chronicle)
        arena.scaleMode = scaleMode
        view?.presentScene(arena, transition: SKTransition.push(with: .left, duration: 0.4))
    }

    private func goBack() {
        let title = TitleVaultScene(size: size)
        title.scaleMode = scaleMode
        view?.presentScene(title, transition: SKTransition.push(with: .right, duration: 0.35))
    }
}
