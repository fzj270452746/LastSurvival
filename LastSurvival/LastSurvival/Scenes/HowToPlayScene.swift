// HowToPlayScene.swift — Game rules & mechanics (Neon Vector Dystopia)

import SpriteKit

class HowToPlayScene: SKScene {

    override func didMove(to view: SKView) {
        backgroundColor = PaletteForge.voidBlack
        buildUI()
    }

    private func buildUI() {
        let sc = size.adaptiveScale
        let safeTop = view?.safeAreaInsets.top ?? 44
        let safeBot = view?.safeAreaInsets.bottom ?? 34

        // Background
        let bg = SKSpriteNode(imageNamed: "bg_main")
        bg.size = size
        bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
        bg.alpha = 0.12
        bg.zPosition = -1
        addChild(bg)

        let overlay = SKShapeNode(rectOf: size)
        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.fillColor = UIColor(red: 0.03, green: 0.02, blue: 0.14, alpha: 0.65)
        overlay.strokeColor = .clear
        overlay.zPosition = 0
        addChild(overlay)

        // ── Header ───────────────────────────────────────────────
        let headerH: CGFloat = 46 * sc
        let headerY = size.height - safeTop - headerH / 2

        let headerBg = SKShapeNode(rectOf: CGSize(width: size.width, height: headerH))
        headerBg.position = CGPoint(x: size.width / 2, y: headerY)
        headerBg.fillColor = UIColor(red: 0.06, green: 0.03, blue: 0.18, alpha: 0.92)
        headerBg.strokeColor = .clear
        headerBg.zPosition = 1
        addChild(headerBg)

        let headerLine = PaletteForge.makeDivider(width: size.width, color: PaletteForge.neonPink, alpha: 0.45)
        headerLine.position = CGPoint(x: size.width / 2, y: headerY - headerH / 2)
        headerLine.zPosition = 2
        addChild(headerLine)

        // BACK button
        let backBtn = ObsidianButtonNode(
            size: CGSize(width: 72 * sc, height: 34 * sc),
            title: "BACK",
            fillColor: PaletteForge.midPurple,
            titleColor: PaletteForge.snowWhite,
            cornerRadius: 8 * sc
        )
        backBtn.position = CGPoint(x: 16 * sc + 36 * sc, y: headerY)
        backBtn.zPosition = 4
        backBtn.onTap = { [weak self] in self?.goBack() }
        addChild(backBtn)

        let titleLbl = PaletteForge.makeLabel(text: "HOW TO PLAY", fontSize: 14 * sc, color: PaletteForge.plasmaBlue, bold: true)
        titleLbl.position = CGPoint(x: size.width / 2, y: headerY)
        titleLbl.zPosition = 2
        addChild(titleLbl)

        // ── Content sections ─────────────────────────────────────
        // Each section has its own accent color — cycling through the neon palette
        let sections: [(icon: String, title: String, lines: [String], accentColor: UIColor)] = [
            ("🎯", "OBJECTIVE", [
                "Survive 30 days in the wasteland.",
                "Keep HP above 0 by managing resources."
            ], PaletteForge.acidLime),
            ("🎰", "SPIN THE REELS", [
                "Spin daily to discover items & threats.",
                "🍖 Food  💧 Water  🔫 Weapon",
                "🧟 Zombie (combat!)  👥 Survivor"
            ], PaletteForge.neonPink),
            ("📦", "RESOURCES", [
                "You consume 1 Food + 1 Water every day.",
                "Running out costs HP per missing unit."
            ], PaletteForge.plasmaBlue),
            ("⚔️", "COMBAT", [
                "1 Weapon deflects 1 zombie attack.",
                "Unblocked zombies deal 1 HP damage each."
            ], PaletteForge.alertRed),
            ("🗺️", "FORAY MODE", [
                "SAFE SEARCH: Normal risk.",
                "DANGER EXPLORE: 2× loot, far more zombies."
            ], PaletteForge.acidLime),
            ("🌤", "WEATHER", [
                "Changes daily, shifting reel chances.",
                "☀️ Normal  🌧 +Water  🔥 −Water drain",
                "🌫 +Zombies  🌪 Scarce everything"
            ], PaletteForge.plasmaBlue),
            ("👤", "CHARACTER CLASSES", [
                "Doctor: +2 HP, heals 1 HP every 3 days.",
                "Soldier: +2 Weapon, earns arms passively.",
                "Engineer: +1 Food/Survivor, earns resources."
            ], PaletteForge.neonPink),
        ]

        let panelW  = size.width - 24 * sc
        let gap: CGFloat = 8 * sc
        let contentTop = headerY - headerH / 2 - 12 * sc
        let contentBot = safeBot + 12 * sc

        var curY = contentTop
        for (i, sec) in sections.enumerated() {
            let ph = sectionHeight(lineCount: sec.lines.count, sc: sc)
            if curY - ph < contentBot { break }

            let node = buildSection(sec, sc: sc, panelW: panelW, panelH: ph)
            node.position = CGPoint(x: size.width / 2, y: curY - ph / 2)
            node.zPosition = 2
            node.alpha = 0
            node.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.06 * Double(i)),
                SKAction.fadeIn(withDuration: 0.22)
            ]))
            addChild(node)
            curY -= ph + gap
        }
    }

    // MARK: - Height calculation

    private func sectionHeight(lineCount: Int, sc: CGFloat) -> CGFloat {
        let headerRowH: CGFloat = 20 * sc
        let lineH: CGFloat      = 15 * sc
        let vertPad: CGFloat    = 16 * sc
        return headerRowH + CGFloat(lineCount) * lineH + vertPad
    }

    // MARK: - Section node

    private func buildSection(
        _ sec: (icon: String, title: String, lines: [String], accentColor: UIColor),
        sc: CGFloat, panelW: CGFloat, panelH: CGFloat
    ) -> SKNode {
        let container = SKNode()

        // Chamfered panel — accent color border (translucent)
        let bg = PaletteForge.makeChamferedPanel(
            size: CGSize(width: panelW, height: panelH),
            chamfer: 8,
            fillColor: PaletteForge.panelBg,
            strokeColor: sec.accentColor.withAlphaComponent(0.40),
            lineWidth: 1.5
        )
        container.addChild(bg)

        // Left accent stripe — solid 3pt vertical line in accent color
        let accentBar = SKShapeNode()
        let barPath = CGMutablePath()
        barPath.move(to:    CGPoint(x: -panelW / 2 + 4, y:  panelH / 2 - 7))
        barPath.addLine(to: CGPoint(x: -panelW / 2 + 4, y: -panelH / 2 + 7))
        accentBar.path = barPath
        accentBar.strokeColor = sec.accentColor
        accentBar.lineWidth = 3
        accentBar.zPosition = 1
        container.addChild(accentBar)

        // Header row
        let topPad: CGFloat     = 8 * sc
        let headerRowH: CGFloat = 20 * sc
        let headerY = panelH / 2 - topPad - headerRowH / 2

        let iconLbl = PaletteForge.makeLabel(text: sec.icon, fontSize: 13 * sc)
        iconLbl.position = CGPoint(x: -panelW / 2 + 18 * sc, y: headerY)
        container.addChild(iconLbl)

        // Title in accent color
        let titleLbl = PaletteForge.makeLabel(text: sec.title, fontSize: 11 * sc, color: sec.accentColor, bold: true)
        titleLbl.position = CGPoint(x: -panelW / 2 + 36 * sc, y: headerY)
        titleLbl.horizontalAlignmentMode = .left
        container.addChild(titleLbl)

        // Body lines
        let lineH: CGFloat = 15 * sc
        let firstLineY = headerY - headerRowH / 2 - 3 * sc - lineH / 2
        let textX = -panelW / 2 + 14 * sc

        for (j, line) in sec.lines.enumerated() {
            let lbl = PaletteForge.makeLabel(
                text: line,
                fontSize: 11 * sc,
                color: PaletteForge.snowWhite.withAlphaComponent(0.82)
            )
            lbl.position = CGPoint(x: textX, y: firstLineY - CGFloat(j) * lineH)
            lbl.horizontalAlignmentMode = .left
            lbl.numberOfLines = 1
            container.addChild(lbl)
        }

        return container
    }

    private func goBack() {
        let scene = TitleVaultScene(size: size)
        scene.scaleMode = scaleMode
        view?.presentScene(scene, transition: SKTransition.push(with: .right, duration: 0.35))
    }
}

typealias VademecumScrollScene = HowToPlayScene
