// EpitaphScene.swift — Game over / victory screen

import SpriteKit

class EpitaphScene: SKScene {

    private let chronicle: VigilChronicle
    private let victory: Bool

    init(size: CGSize, chronicle: VigilChronicle, victory: Bool) {
        self.chronicle = chronicle
        self.victory = victory
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    override func didMove(to view: SKView) {
        backgroundColor = PaletteForge.obsidian
        saveRunAndUnlockAchievements()
        buildUI()
    }

    private func saveRunAndUnlockAchievements() {
        let record = RunRecord(chronicle: chronicle, victory: victory)
        RunArchiveStore.shared.save(record: record)
        let newAchievements = AchievementRegistry.shared.evaluate(record: record)
        if !newAchievements.isEmpty {
            run(SKAction.wait(forDuration: 1.6)) { [weak self] in
                self?.showAchievementToast(newAchievements)
            }
        }
    }

    private func showAchievementToast(_ achievements: [Achievement]) {
        let sc = size.adaptiveScale
        var delay: TimeInterval = 0
        for ach in achievements {
            let toast = buildToast(achievement: ach, sc: sc)
            toast.position = CGPoint(x: size.width / 2, y: size.height * 0.88)
            toast.zPosition = 20
            toast.alpha = 0
            addChild(toast)
            toast.run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.group([
                    SKAction.fadeIn(withDuration: 0.25),
                    SKAction.moveBy(x: 0, y: 6 * sc, duration: 0.25)
                ]),
                SKAction.wait(forDuration: 2.2),
                SKAction.group([
                    SKAction.fadeOut(withDuration: 0.3),
                    SKAction.moveBy(x: 0, y: 8 * sc, duration: 0.3)
                ]),
                SKAction.removeFromParent()
            ]))
            delay += 2.8
        }
    }

    private func buildToast(achievement: Achievement, sc: CGFloat) -> SKNode {
        let container = SKNode()
        let toastW = size.width * 0.76
        let toastH = 44 * sc
        let bg = PaletteForge.makeRoundedPanel(
            size: CGSize(width: toastW, height: toastH),
            cornerRadius: 10 * sc,
            fillColor: UIColor(red: 0.15, green: 0.12, blue: 0.05, alpha: 0.96),
            strokeColor: PaletteForge.cinderGold,
            lineWidth: 1.5
        )
        container.addChild(bg)

        let iconLbl = PaletteForge.makeLabel(text: achievement.icon, fontSize: 20 * sc)
        iconLbl.position = CGPoint(x: -toastW / 2 + 22 * sc, y: 0)
        container.addChild(iconLbl)

        let titleLbl = PaletteForge.makeLabel(text: "Achievement: \(achievement.title)", fontSize: 10 * sc, color: PaletteForge.cinderGold, bold: true)
        titleLbl.position = CGPoint(x: 6 * sc, y: toastH * 0.13)
        container.addChild(titleLbl)

        let descLbl = PaletteForge.makeLabel(text: achievement.description, fontSize: 9 * sc, color: PaletteForge.ashWhite.withAlphaComponent(0.75))
        descLbl.position = CGPoint(x: 6 * sc, y: -toastH * 0.22)
        container.addChild(descLbl)

        return container
    }

    private func buildUI() {
        let sc = size.adaptiveScale

        // Background
        let bg = SKSpriteNode(imageNamed: "bg_main")
        bg.size = size
        bg.position = CGPoint(x: size.width/2, y: size.height/2)
        bg.alpha = victory ? 0.30 : 0.20
        bg.zPosition = -1
        addChild(bg)

        // Color overlay
        let overlay = SKShapeNode(rectOf: size)
        overlay.position = CGPoint(x: size.width/2, y: size.height/2)
        overlay.fillColor = victory
            ? UIColor(red: 0.05, green: 0.12, blue: 0.08, alpha: 0.6)
            : UIColor(red: 0.12, green: 0.03, blue: 0.03, alpha: 0.7)
        overlay.strokeColor = .clear
        overlay.zPosition = 0
        addChild(overlay)

        // Result icon / emoji label
        let iconLbl = PaletteForge.makeLabel(
            text: victory ? "🏆" : "💀",
            fontSize: 72 * sc,
            color: .white,
            bold: false
        )
        iconLbl.position = CGPoint(x: size.width/2, y: size.height * 0.72)
        iconLbl.zPosition = 2
        iconLbl.alpha = 0
        iconLbl.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.3),
            SKAction.group([
                SKAction.fadeIn(withDuration: 0.4),
                SKAction.sequence([
                    SKAction.scale(to: 1.3, duration: 0.2),
                    SKAction.scale(to: 1.0, duration: 0.2)
                ])
            ])
        ]))
        addChild(iconLbl)

        // Result title
        let resultTitle = victory ? "YOU SURVIVED" : "YOU PERISHED"
        let titleColor = victory ? PaletteForge.cinderGold : PaletteForge.bloodRed
        let titleLbl = PaletteForge.makeLabel(text: resultTitle, fontSize: 32 * sc, color: titleColor, bold: true)
        titleLbl.position = CGPoint(x: size.width/2, y: size.height * 0.60)
        titleLbl.zPosition = 2
        titleLbl.alpha = 0
        titleLbl.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.55),
            SKAction.fadeIn(withDuration: 0.35)
        ]))
        addChild(titleLbl)

        // Subtitle
        let subtitle = victory
            ? "30 days in the wasteland. A legend."
            : "Day \(chronicle.diurnalIndex) — The wasteland claims another soul."
        let subLbl = PaletteForge.makeLabel(text: subtitle, fontSize: 13 * sc, color: PaletteForge.ashWhite.withAlphaComponent(0.8))
        subLbl.position = CGPoint(x: size.width/2, y: size.height * 0.53)
        subLbl.zPosition = 2
        subLbl.numberOfLines = 2
        subLbl.preferredMaxLayoutWidth = size.width * 0.82
        subLbl.alpha = 0
        subLbl.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.7),
            SKAction.fadeIn(withDuration: 0.35)
        ]))
        addChild(subLbl)

        // Stats panel
        buildStatsPanel(sc: sc)

        // Buttons
        let btnW = 200 * sc
        let btnH = 50 * sc

        let retryBtn = ObsidianButtonNode(
            size: CGSize(width: btnW, height: btnH),
            title: "PLAY AGAIN",
            fillColor: PaletteForge.cinderGold,
            titleColor: PaletteForge.obsidian,
            cornerRadius: 25 * sc
        )
        retryBtn.position = CGPoint(x: size.width/2, y: size.height * 0.14)
        retryBtn.zPosition = 4
        retryBtn.alpha = 0
        retryBtn.onTap = { [weak self] in self?.restartGame() }
        retryBtn.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            SKAction.fadeIn(withDuration: 0.35)
        ]))
        addChild(retryBtn)

        let menuBtn = ObsidianButtonNode(
            size: CGSize(width: btnW * 0.7, height: btnH * 0.75),
            title: "MAIN MENU",
            fillColor: PaletteForge.slateGray,
            titleColor: PaletteForge.ashWhite,
            cornerRadius: 18 * sc
        )
        menuBtn.position = CGPoint(x: size.width/2, y: size.height * 0.07)
        menuBtn.zPosition = 4
        menuBtn.alpha = 0
        menuBtn.onTap = { [weak self] in self?.goToMenu() }
        menuBtn.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.1),
            SKAction.fadeIn(withDuration: 0.35)
        ]))
        addChild(menuBtn)
    }

    private func buildStatsPanel(sc: CGFloat) {
        let panelW = size.width - 40 * sc
        let panelH: CGFloat = 130 * sc
        let panel = PaletteForge.makeRoundedPanel(
            size: CGSize(width: panelW, height: panelH),
            cornerRadius: 16 * sc,
            fillColor: PaletteForge.panelBg,
            strokeColor: PaletteForge.cinderGold.withAlphaComponent(0.35),
            lineWidth: 1
        )
        panel.position = CGPoint(x: size.width/2, y: size.height * 0.36)
        panel.zPosition = 3
        panel.alpha = 0
        panel.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.85),
            SKAction.fadeIn(withDuration: 0.35)
        ]))
        addChild(panel)

        let stats: [(String, String)] = [
            ("Days Survived", "\(chronicle.diurnalIndex)"),
            ("Zombies Slain", "\(chronicle.revenantTally)"),
            ("Survivors Met", "\(chronicle.wayfarerTally)"),
            ("HP Remaining", "\(max(0, chronicle.vitality))")
        ]

        let colSpacing = panelW * 0.46
        let rowSpacing = panelH * 0.42

        for (i, (label, value)) in stats.enumerated() {
            let col = CGFloat(i % 2) - 0.5
            let row = CGFloat(i / 2)
            let x = col * colSpacing
            let y = panelH * 0.22 - row * rowSpacing

            let valLbl = PaletteForge.makeLabel(text: value, fontSize: 22 * sc, color: PaletteForge.cinderGold, bold: true)
            valLbl.position = CGPoint(x: x, y: y)
            panel.addChild(valLbl)

            let nameLbl = PaletteForge.makeLabel(text: label, fontSize: 9 * sc, color: PaletteForge.ashWhite.withAlphaComponent(0.65))
            nameLbl.position = CGPoint(x: x, y: y - 18 * sc)
            panel.addChild(nameLbl)
        }
    }

    private func restartGame() {
        let scene = ArchetypeVaultScene(size: size)
        scene.scaleMode = scaleMode
        let trans = SKTransition.fade(withDuration: 0.5)
        view?.presentScene(scene, transition: trans)
    }

    private func goToMenu() {
        let scene = TitleVaultScene(size: size)
        scene.scaleMode = scaleMode
        let trans = SKTransition.fade(withDuration: 0.5)
        view?.presentScene(scene, transition: trans)
    }
}
