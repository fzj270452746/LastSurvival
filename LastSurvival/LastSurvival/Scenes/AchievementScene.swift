// AchievementScene.swift — Achievement showcase screen

import SpriteKit

class AchievementScene: SKScene {

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
        bg.alpha = 0.20
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

        let registry = AchievementRegistry.shared
        let titleText = "ACHIEVEMENTS  \(registry.unlockedCount)/\(registry.all.count)"
        let titleLbl = PaletteForge.makeLabel(text: titleText, fontSize: 13 * sc, color: PaletteForge.cinderGold, bold: true)
        titleLbl.position = CGPoint(x: size.width / 2, y: headerY)
        titleLbl.zPosition = 2
        addChild(titleLbl)

        // ── Achievement grid ─────────────────────────────────────
        let achievements = registry.all
        let cardW: CGFloat = (size.width - 36 * sc) / 2
        let cardH: CGFloat = 72 * sc
        let gap: CGFloat   = 10 * sc
        let listTop = headerY - headerH / 2 - 14 * sc
        let listBot = safeBot + 14 * sc
        let cols = 2
        let visRows = Int((listTop - listBot) / (cardH + gap))
        let maxCards = visRows * cols

        let displayAchs = Array(achievements.prefix(maxCards))
        for (i, ach) in displayAchs.enumerated() {
            let col = i % cols
            let row = i / cols
            let x = 12 * sc + cardW / 2 + CGFloat(col) * (cardW + gap)
            let y = listTop - cardH / 2 - CGFloat(row) * (cardH + gap)
            let card = buildCard(achievement: ach, sc: sc, cardW: cardW, cardH: cardH)
            card.position = CGPoint(x: x, y: y)
            card.zPosition = 2
            card.alpha = 0
            card.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.04 * Double(i)),
                SKAction.fadeIn(withDuration: 0.20)
            ]))
            addChild(card)
        }
    }

    private func buildCard(achievement: Achievement, sc: CGFloat, cardW: CGFloat, cardH: CGFloat) -> SKNode {
        let container = SKNode()
        let locked = !achievement.isUnlocked

        let bg = PaletteForge.makeRoundedPanel(
            size: CGSize(width: cardW, height: cardH),
            cornerRadius: 10 * sc,
            fillColor: locked
                ? UIColor(red: 0.10, green: 0.10, blue: 0.13, alpha: 0.85)
                : UIColor(red: 0.08, green: 0.15, blue: 0.10, alpha: 0.92),
            strokeColor: locked
                ? PaletteForge.slateGray.withAlphaComponent(0.3)
                : PaletteForge.cinderGold.withAlphaComponent(0.55),
            lineWidth: 1
        )
        container.addChild(bg)

        // Icon
        let iconText = locked ? "🔒" : achievement.icon
        let iconLbl = PaletteForge.makeLabel(text: iconText, fontSize: 20 * sc)
        iconLbl.position = CGPoint(x: -cardW / 2 + 20 * sc, y: 0)
        container.addChild(iconLbl)

        // Text area starts just past the icon, ends at right edge with margin
        let textX = -cardW / 2 + 40 * sc
        let textMaxW = cardW - 48 * sc

        // Title
        let titleColor = locked ? PaletteForge.ashWhite.withAlphaComponent(0.35) : PaletteForge.cinderGold
        let titleLbl = PaletteForge.makeLabel(text: achievement.title, fontSize: 10 * sc, color: titleColor, bold: true)
        titleLbl.position = CGPoint(x: textX, y: cardH * 0.14)
        titleLbl.horizontalAlignmentMode = .left
        titleLbl.numberOfLines = 1
        titleLbl.preferredMaxLayoutWidth = textMaxW
        container.addChild(titleLbl)

        // Description
        let descColor = locked ? PaletteForge.ashWhite.withAlphaComponent(0.2) : PaletteForge.ashWhite.withAlphaComponent(0.72)
        let descLbl = PaletteForge.makeLabel(text: achievement.description, fontSize: 9 * sc, color: descColor)
        descLbl.position = CGPoint(x: textX, y: -cardH * 0.20)
        descLbl.horizontalAlignmentMode = .left
        descLbl.numberOfLines = 2
        descLbl.preferredMaxLayoutWidth = textMaxW
        container.addChild(descLbl)

        // Unlock date
        if let date = achievement.unlockedDate {
            let df = DateFormatter()
            df.dateFormat = "MM/dd"
            let dateLbl = PaletteForge.makeLabel(text: df.string(from: date), fontSize: 8 * sc, color: PaletteForge.jadeTeal.withAlphaComponent(0.65))
            dateLbl.position = CGPoint(x: cardW / 2 - 8 * sc, y: cardH * 0.28)
            dateLbl.horizontalAlignmentMode = .right
            container.addChild(dateLbl)
        }

        return container
    }

    private func goBack() {
        let scene = TitleVaultScene(size: size)
        scene.scaleMode = scaleMode
        view?.presentScene(scene, transition: SKTransition.push(with: .right, duration: 0.35))
    }
}
