// HowToPlayScene.swift — Game rules & mechanics (Neon Vector Dystopia)

import SpriteKit

// MARK: - HowToPlayScene: inherits ProstyleProscenium (Template Method)
class HowToPlayScene: ProstyleProscenium {

    override func didMove(to view: SKView) {
        // Customise substrate alpha to match original values
        substrateBgAlpha  = 0.12
        substrateDimAlpha = 0.65
        headerConfig = ProsceniumHeaderConfig.standard(
            title: "HOW TO PLAY",
            tint:  DesignToken.ceruleanVolt,
            back:  { [weak self] in self?.goBack() }
        )
        super.didMove(to: view)
    }

    // MARK: - Template Method override
    override func buildContent() {
        mountSections()
    }

    // MARK: - Sections content

    private func mountSections() {
        let sc      = displayScale
        let safeBot = safeBottomInset

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
        let contentTop = headerBottomY - 12 * sc
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

        let bg = PaletteForge.makeChamferedPanel(
            size: CGSize(width: panelW, height: panelH),
            chamfer: 8,
            fillColor: PaletteForge.panelBg,
            strokeColor: sec.accentColor.withAlphaComponent(0.40),
            lineWidth: 1.5
        )
        container.addChild(bg)

        let accentBar = SKShapeNode()
        let barPath = CGMutablePath()
        barPath.move(to:    CGPoint(x: -panelW / 2 + 4, y:  panelH / 2 - 7))
        barPath.addLine(to: CGPoint(x: -panelW / 2 + 4, y: -panelH / 2 + 7))
        accentBar.path = barPath
        accentBar.strokeColor = sec.accentColor
        accentBar.lineWidth = 3
        accentBar.zPosition = 1
        container.addChild(accentBar)

        let topPad: CGFloat     = 8 * sc
        let headerRowH: CGFloat = 20 * sc
        let headerY = panelH / 2 - topPad - headerRowH / 2

        let iconLbl = PaletteForge.makeLabel(text: sec.icon, fontSize: 13 * sc)
        iconLbl.position = CGPoint(x: -panelW / 2 + 18 * sc, y: headerY)
        container.addChild(iconLbl)

        let titleLbl = PaletteForge.makeLabel(text: sec.title, fontSize: 11 * sc, color: sec.accentColor, bold: true)
        titleLbl.position = CGPoint(x: -panelW / 2 + 36 * sc, y: headerY)
        titleLbl.horizontalAlignmentMode = .left
        container.addChild(titleLbl)

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
        dispatchEgress(RetreatEgress())
    }
}

typealias VademecumScrollScene = HowToPlayScene
