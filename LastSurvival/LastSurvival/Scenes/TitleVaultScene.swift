// TitleVaultScene.swift — Title / main menu screen

import SpriteKit

class TitleVaultScene: SKScene {

    override func didMove(to view: SKView) {
        backgroundColor = PaletteForge.obsidian
        buildUI()
    }

    private func buildUI() {
        let sc = size.adaptiveScale

        // Background
        let bg = SKSpriteNode(imageNamed: "bg_main")
        bg.size = size
        bg.position = CGPoint(x: size.width/2, y: size.height/2)
        bg.alpha = 0.35
        bg.zPosition = -1
        addChild(bg)

        // Vignette overlay
        let vignette = SKShapeNode(rectOf: size)
        vignette.position = CGPoint(x: size.width/2, y: size.height/2)
        vignette.fillColor = UIColor(red: 0.02, green: 0.02, blue: 0.05, alpha: 0.55)
        vignette.strokeColor = .clear
        vignette.zPosition = 0
        addChild(vignette)

        // Decorative top line
        let topLine = SKShapeNode()
        let linePath = CGMutablePath()
        linePath.move(to: CGPoint(x: size.width * 0.1, y: size.height * 0.82))
        linePath.addLine(to: CGPoint(x: size.width * 0.9, y: size.height * 0.82))
        topLine.path = linePath
        topLine.strokeColor = PaletteForge.cinderGold.withAlphaComponent(0.4)
        topLine.lineWidth = 1
        topLine.zPosition = 1
        addChild(topLine)

        // Subtitle tag
        let tagLbl = PaletteForge.makeLabel(text: "LAST SLOT SURVIVAL", fontSize: 11 * sc, color: PaletteForge.cinderGold.withAlphaComponent(0.8))
        tagLbl.position = CGPoint(x: size.width/2, y: size.height * 0.80)
        tagLbl.zPosition = 2
        tagLbl.fontName = "AvenirNext-Heavy"
        let tracking = SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.5, duration: 1.2),
            SKAction.fadeAlpha(to: 1.0, duration: 1.2)
        ]))
        tagLbl.run(tracking)
        addChild(tagLbl)

        // Main title
        let titleLbl = PaletteForge.makeLabel(text: "LAST", fontSize: 58 * sc, color: PaletteForge.ashWhite, bold: true)
        titleLbl.position = CGPoint(x: size.width/2, y: size.height * 0.70)
        titleLbl.zPosition = 2
        addChild(titleLbl)

        let title2Lbl = PaletteForge.makeLabel(text: "SURVIVAL", fontSize: 38 * sc, color: PaletteForge.cinderGold, bold: true)
        title2Lbl.position = CGPoint(x: size.width/2, y: size.height * 0.63)
        title2Lbl.zPosition = 2
        addChild(title2Lbl)

        // Decorative bottom line
        let botLine = SKShapeNode()
        let botPath = CGMutablePath()
        botPath.move(to: CGPoint(x: size.width * 0.2, y: size.height * 0.60))
        botPath.addLine(to: CGPoint(x: size.width * 0.8, y: size.height * 0.60))
        botLine.path = botPath
        botLine.strokeColor = PaletteForge.cinderGold.withAlphaComponent(0.4)
        botLine.lineWidth = 1
        botLine.zPosition = 1
        addChild(botLine)

        // Flavor text
        let flavorLbl = PaletteForge.makeLabel(
            text: "Spin the reels. Survive the apocalypse.",
            fontSize: 13 * sc,
            color: PaletteForge.ashWhite.withAlphaComponent(0.7)
        )
        flavorLbl.position = CGPoint(x: size.width/2, y: size.height * 0.54)
        flavorLbl.zPosition = 2
        addChild(flavorLbl)

        // Start button
        let btnW = 220 * sc
        let btnH = 54 * sc
        let startBtn = ObsidianButtonNode(
            size: CGSize(width: btnW, height: btnH),
            title: "START GAME",
            fillColor: PaletteForge.cinderGold,
            titleColor: PaletteForge.obsidian,
            cornerRadius: 27 * sc
        )
        startBtn.position = CGPoint(x: size.width/2, y: size.height * 0.40)
        startBtn.zPosition = 3
        startBtn.onTap = { [weak self] in self?.goToCharacterSelect() }
        addChild(startBtn)

        // Pulse glow on button
        startBtn.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.03, duration: 0.9),
            SKAction.scale(to: 1.0, duration: 0.9)
        ])))

        // ── Secondary buttons row ────────────────────────────────
        // Use full screen width so "ACHIEVEMENTS" text doesn't overflow
        let secBtnW = (size.width - 32 * sc) / 2   // 14pt margin each side, 4pt gap
        let secBtnH = 40 * sc
        let secY = size.height * 0.29

        let historyBtn = ObsidianButtonNode(
            size: CGSize(width: secBtnW, height: secBtnH),
            title: "HISTORY",
            fillColor: PaletteForge.slateGray,
            titleColor: PaletteForge.ashWhite,
            cornerRadius: 10 * sc
        )
        historyBtn.position = CGPoint(x: 14 * sc + secBtnW / 2, y: secY)
        historyBtn.zPosition = 3
        historyBtn.onTap = { [weak self] in self?.goToHistory() }
        addChild(historyBtn)

        let achBtn = ObsidianButtonNode(
            size: CGSize(width: secBtnW, height: secBtnH),
            title: "ACHIEVEMENTS",
            fillColor: PaletteForge.slateGray,
            titleColor: PaletteForge.cinderGold,
            cornerRadius: 10 * sc
        )
        achBtn.position = CGPoint(x: size.width - 14 * sc - secBtnW / 2, y: secY)
        achBtn.zPosition = 3
        achBtn.onTap = { [weak self] in self?.goToAchievements() }
        addChild(achBtn)

        let howBtn = ObsidianButtonNode(
            size: CGSize(width: btnW, height: secBtnH),
            title: "HOW TO PLAY",
            fillColor: PaletteForge.obsidian,
            titleColor: PaletteForge.ashWhite.withAlphaComponent(0.85),
            cornerRadius: 10 * sc
        )
        howBtn.position = CGPoint(x: size.width/2, y: size.height * 0.20)
        howBtn.zPosition = 3
        howBtn.onTap = { [weak self] in self?.goToHowToPlay() }
        addChild(howBtn)

        // Best run blurb (if any runs exist)
        let store = RunArchiveStore.shared
        if store.totalRuns > 0 {
            let blurb = "Best: \(store.bestDays) days  |  Runs: \(store.totalRuns)  |  Victories: \(store.totalVictories)"
            let bestLbl = PaletteForge.makeLabel(text: blurb, fontSize: 10 * sc, color: PaletteForge.ashWhite.withAlphaComponent(0.5))
            bestLbl.position = CGPoint(x: size.width/2, y: size.height * 0.12)
            bestLbl.zPosition = 2
            addChild(bestLbl)
        }

        // Version label
        let verLbl = PaletteForge.makeLabel(text: "v1.0", fontSize: 10 * sc, color: PaletteForge.ashWhite.withAlphaComponent(0.3))
        verLbl.position = CGPoint(x: size.width/2, y: size.height * 0.06)
        verLbl.zPosition = 2
        addChild(verLbl)

        // Entrance animation
        let nodes: [SKNode] = [titleLbl, title2Lbl, flavorLbl, startBtn]
        for (i, n) in nodes.enumerated() {
            n.alpha = 0
            n.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.3 + Double(i) * 0.15),
                SKAction.group([
                    SKAction.fadeIn(withDuration: 0.4),
                    SKAction.moveBy(x: 0, y: 12 * sc, duration: 0.4)
                ])
            ]))
        }
    }

    private func goToCharacterSelect() {
        let next = ArchetypeVaultScene(size: size)
        next.scaleMode = scaleMode
        let trans = SKTransition.push(with: .left, duration: 0.4)
        view?.presentScene(next, transition: trans)
    }

    private func goToHistory() {
        let next = RunHistoryScene(size: size)
        next.scaleMode = scaleMode
        view?.presentScene(next, transition: SKTransition.push(with: .left, duration: 0.35))
    }

    private func goToAchievements() {
        let next = AchievementScene(size: size)
        next.scaleMode = scaleMode
        view?.presentScene(next, transition: SKTransition.push(with: .left, duration: 0.35))
    }

    private func goToHowToPlay() {
        let next = HowToPlayScene(size: size)
        next.scaleMode = scaleMode
        view?.presentScene(next, transition: SKTransition.push(with: .left, duration: 0.35))
    }
}
