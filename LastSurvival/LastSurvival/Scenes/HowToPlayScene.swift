// HowToPlayScene.swift — Game rules & mechanics explanation

import SpriteKit

class HowToPlayScene: SKScene {

    override func didMove(to view: SKView) {
        backgroundColor = PaletteForge.obsidian
        buildUI()
    }

    private func buildUI() {
        let sc = size.adaptiveScale
        let safeTop = view?.safeAreaInsets.top ?? 44
        let safeBot = view?.safeAreaInsets.bottom ?? 34

        // Background
        let bg = SKSpriteNode(imageNamed: "bg_main")
        bg.size = size
        bg.position = CGPoint(x: size.width/2, y: size.height/2)
        bg.alpha = 0.18
        bg.zPosition = -1
        addChild(bg)

        // ── Header ──────────────────────────────────────────────
        let headerH: CGFloat = 44 * sc
        let headerY = size.height - safeTop - headerH / 2

        let headerBg = SKShapeNode(rectOf: CGSize(width: size.width, height: headerH))
        headerBg.position = CGPoint(x: size.width / 2, y: headerY)
        headerBg.fillColor = UIColor(white: 0, alpha: 0.55)
        headerBg.strokeColor = .clear
        headerBg.zPosition = 1
        addChild(headerBg)

        let backBtn = ObsidianButtonNode(
            size: CGSize(width: 68 * sc, height: 34 * sc),
            title: "BACK",
            fillColor: PaletteForge.slateGray,
            titleColor: PaletteForge.ashWhite,
            cornerRadius: 8 * sc
        )
        backBtn.position = CGPoint(x: 16 * sc + 34 * sc, y: headerY)
        backBtn.zPosition = 4
        backBtn.onTap = { [weak self] in self?.goBack() }
        addChild(backBtn)

        let titleLbl = PaletteForge.makeLabel(text: "HOW TO PLAY", fontSize: 14 * sc, color: PaletteForge.cinderGold, bold: true)
        titleLbl.position = CGPoint(x: size.width / 2, y: headerY)
        titleLbl.zPosition = 2
        addChild(titleLbl)

        // ── Sections ─────────────────────────────────────────────
        // Each body entry is a pre-split array of short lines (all fit in one visual line).
        // Height is computed exactly: no estimation surprises.
        let sections: [(icon: String, title: String, lines: [String])] = [
            ("🎯", "OBJECTIVE", [
                "Survive 30 days in the wasteland.",
                "Keep HP above 0 by managing resources."
            ]),
            ("🎰", "SPIN THE REELS", [
                "Spin daily to discover items & threats.",
                "🍖 Food  💧 Water  🔫 Weapon",
                "🧟 Zombie (combat!)  👥 Survivor"
            ]),
            ("📦", "RESOURCES", [
                "You consume 1 Food + 1 Water every day.",
                "Running out costs HP per missing unit."
            ]),
            ("⚔️", "COMBAT", [
                "1 Weapon deflects 1 zombie attack.",
                "Unblocked zombies deal 1 HP damage each."
            ]),
            ("🗺️", "FORAY MODE", [
                "SAFE SEARCH: Normal risk.",
                "DANGER EXPLORE: 2× loot, far more zombies."
            ]),
            ("🌤", "WEATHER", [
                "Changes daily, shifting reel chances.",
                "☀️ Normal  🌧 +Water  🔥 −Water drain",
                "🌫 +Zombies  🌪 Scarce everything"
            ]),
            ("👤", "CHARACTER CLASSES", [
                "Doctor: +2 HP, heals 1 HP every 3 days.",
                "Soldier: +2 Weapon, earns arms passively.",
                "Engineer: +1 Food/Survivor, earns resources."
            ]),
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

    // ── Height calculation ────────────────────────────────────────
    // Exact: header row + N body lines + fixed padding. No estimation.
    private func sectionHeight(lineCount: Int, sc: CGFloat) -> CGFloat {
        let headerRowH: CGFloat = 20 * sc
        let lineH: CGFloat      = 15 * sc
        let vertPad: CGFloat    = 16 * sc   // 8pt top + 8pt bottom
        return headerRowH + CGFloat(lineCount) * lineH + vertPad
    }

    // ── Section node ──────────────────────────────────────────────
    private func buildSection(
        _ sec: (icon: String, title: String, lines: [String]),
        sc: CGFloat, panelW: CGFloat, panelH: CGFloat
    ) -> SKNode {
        let container = SKNode()

        let bg = PaletteForge.makeRoundedPanel(
            size: CGSize(width: panelW, height: panelH),
            cornerRadius: 10 * sc,
            fillColor: PaletteForge.panelBg,
            strokeColor: PaletteForge.slateGray.withAlphaComponent(0.4),
            lineWidth: 1
        )
        container.addChild(bg)

        // Header row: pinned 8pt from panel top
        let topPad: CGFloat     = 8 * sc
        let headerRowH: CGFloat = 20 * sc
        let headerY = panelH / 2 - topPad - headerRowH / 2

        let iconLbl = PaletteForge.makeLabel(text: sec.icon, fontSize: 14 * sc)
        iconLbl.position = CGPoint(x: -panelW / 2 + 16 * sc, y: headerY)
        container.addChild(iconLbl)

        let titleLbl = PaletteForge.makeLabel(text: sec.title, fontSize: 11 * sc, color: PaletteForge.cinderGold, bold: true)
        titleLbl.position = CGPoint(x: -panelW / 2 + 34 * sc, y: headerY)
        titleLbl.horizontalAlignmentMode = .left
        container.addChild(titleLbl)

        // Body lines: each placed exactly one lineH below the previous
        let lineH: CGFloat = 15 * sc
        let firstLineY = headerY - headerRowH / 2 - 3 * sc - lineH / 2
        let textX = -panelW / 2 + 14 * sc

        for (j, line) in sec.lines.enumerated() {
            let lbl = PaletteForge.makeLabel(text: line, fontSize: 11 * sc,
                                              color: PaletteForge.ashWhite.withAlphaComponent(0.85))
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
