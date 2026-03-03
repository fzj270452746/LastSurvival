// EpitaphScene.swift — Game over / victory screen (refactored)

import SpriteKit

// MARK: - EpitaphTheme: visual configuration based on outcome
private struct EpitaphTheme {
    let resultIcon:      String
    let headlineText:    String
    let headlineTint:    UIColor
    let overlayTint:     UIColor
    let panelBorderTint: UIColor
    let statAccentTint:  UIColor
    let backdropAlpha:   CGFloat

    static func from(victory: Bool) -> EpitaphTheme {
        if victory {
            return EpitaphTheme(
                resultIcon:      "🏆",
                headlineText:    "YOU SURVIVED",
                headlineTint:    DesignToken.phosphorLime,
                overlayTint:     UIColor(red: 0.06, green: 0.18, blue: 0.04, alpha: 0.50),
                panelBorderTint: DesignToken.phosphorLime,
                statAccentTint:  DesignToken.phosphorLime,
                backdropAlpha:   0.18
            )
        } else {
            return EpitaphTheme(
                resultIcon:      "💀",
                headlineText:    "YOU PERISHED",
                headlineTint:    DesignToken.vermillionAlert,
                overlayTint:     UIColor(red: 0.18, green: 0.02, blue: 0.06, alpha: 0.60),
                panelBorderTint: DesignToken.vermillionAlert,
                statAccentTint:  DesignToken.radiantCrimson,
                backdropAlpha:   0.14
            )
        }
    }
}

// MARK: - StatEntry: single stat label/value pair
private struct StatEntry {
    let caption: String
    let value:   String
}

// MARK: - StatCardBuilder: 2-column statistics panel constructor
private class StatCardBuilder {
    private let entries:      [StatEntry]
    private let accentTint:   UIColor
    private let borderTint:   UIColor

    init(entries: [StatEntry], accent: UIColor, border: UIColor) {
        self.entries    = entries
        self.accentTint = accent
        self.borderTint = border
    }

    func buildPanel(sceneWidth: CGFloat, scale sc: CGFloat) -> SKNode {
        let panelW: CGFloat = sceneWidth - 38 * sc
        let panelH: CGFloat = 134 * sc

        let wrapper = SKNode()
        let surface = GeometryForge.panelNode(
            size:        CGSize(width: panelW, height: panelH),
            cutDepth:    10,
            fill:        DesignToken.vaultSurface,
            stroke:      borderTint.withAlphaComponent(0.45),
            strokeWidth: 1.5
        )
        wrapper.addChild(surface)

        let columnStride = panelW * 0.46
        let rowStride    = panelH * 0.44

        entries.enumerated().forEach { idx, entry in
            let columnOffset: CGFloat = CGFloat(idx % 2) - 0.5
            let rowOffset:    CGFloat = CGFloat(idx / 2)
            let xPos = columnOffset * columnStride
            let yPos = panelH * 0.22 - rowOffset * rowStride

            let valueLabel = TypographyScale.labelNode(
                text:   entry.value,
                size:   24 * sc,
                tint:   accentTint,
                weight: .headline
            )
            valueLabel.position = CGPoint(x: xPos, y: yPos)
            surface.addChild(valueLabel)

            let captionLabel = TypographyScale.labelNode(
                text: entry.caption,
                size: 8 * sc,
                tint: DesignToken.ashNebula
            )
            captionLabel.position = CGPoint(x: xPos, y: yPos - 19 * sc)
            surface.addChild(captionLabel)
        }
        return wrapper
    }
}

// MARK: - RunPostProcessor: saves run and evaluates achievements
private enum RunPostProcessor {
    static func finalize(chronicle: VigilChronicle, victory: Bool) -> [Achievement] {
        let record = RunRecord(chronicle: chronicle, victory: victory)
        RunArchiveStore.shared.save(record: record)
        return AchievementRegistry.shared.evaluate(record: record)
    }
}

// MARK: - AchievementRevealQueue: sequentially reveals achievement toasts
private class AchievementRevealQueue {
    private let sceneSize: CGSize
    private let scale:     CGFloat
    weak var scene: SKScene?

    init(sceneSize: CGSize, scale: CGFloat, scene: SKScene) {
        self.sceneSize = sceneSize
        self.scale     = scale
        self.scene     = scene
    }

    func present(_ achievements: [Achievement], initialDelay: TimeInterval = 1.6) {
        var cumulativeDelay = initialDelay
        achievements.forEach { ach in
            showToast(for: ach, after: cumulativeDelay)
            cumulativeDelay += 2.8
        }
    }

    private func showToast(for ach: Achievement, after delay: TimeInterval) {
        let sc    = scale
        let toast = buildToast(ach: ach, sc: sc)
        toast.position  = CGPoint(x: sceneSize.width / 2, y: sceneSize.height * 0.88)
        toast.zPosition = 20
        toast.alpha     = 0
        scene?.addChild(toast)
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
    }

    private func buildToast(ach: Achievement, sc: CGFloat) -> SKNode {
        let toastW = sceneSize.width * 0.78
        let toastH = 46 * sc
        let root   = SKNode()

        let toastBg = GeometryForge.panelNode(
            size:        CGSize(width: toastW, height: toastH),
            cutDepth:    8,
            fill:        UIColor(red: 0.08, green: 0.04, blue: 0.22, alpha: 0.97),
            stroke:      DesignToken.phosphorLime,
            strokeWidth: 1.5
        )
        root.addChild(toastBg)

        let iconNode = TypographyScale.labelNode(text: ach.icon, size: 20 * sc)
        iconNode.position = CGPoint(x: -toastW / 2 + 22 * sc, y: 0)
        root.addChild(iconNode)

        let titleNode = TypographyScale.labelNode(
            text:   "ACHIEVEMENT: \(ach.title)",
            size:   10 * sc,
            tint:   DesignToken.phosphorLime,
            weight: .headline
        )
        titleNode.position = CGPoint(x: 6 * sc, y: toastH * 0.13)
        root.addChild(titleNode)

        let descNode = TypographyScale.labelNode(
            text: ach.description,
            size: 9 * sc,
            tint: DesignToken.frostSheen.withAlphaComponent(0.75)
        )
        descNode.position = CGPoint(x: 6 * sc, y: -toastH * 0.22)
        root.addChild(descNode)

        return root
    }
}

// MARK: - EpitaphScene
class EpitaphScene: SKScene {

    private let chronicle: VigilChronicle
    private let victory:   Bool
    private lazy var theme = EpitaphTheme.from(victory: victory)

    init(size: CGSize, chronicle: VigilChronicle, victory: Bool) {
        self.chronicle = chronicle
        self.victory   = victory
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) not implemented") }

    override func didMove(to view: SKView) {
        backgroundColor = DesignToken.cosmicInk

        // Persist run and collect newly-unlocked achievements
        let unlocked = RunPostProcessor.finalize(chronicle: chronicle, victory: victory)

        assembleScene()

        // Schedule achievement toasts if any unlocked
        if !unlocked.isEmpty {
            AchievementRevealQueue(sceneSize: size, scale: size.calibration, scene: self)
                .present(unlocked, initialDelay: 1.6)
        }
    }

    // MARK: - Scene assembly steps

    private func assembleScene() {
        let sc = size.calibration
        mountBackground(sc: sc)
        mountResultIcon(sc: sc)
        mountHeadline(sc: sc)
        mountSubtitle(sc: sc)
        mountStatPanel(sc: sc)
        mountButtons(sc: sc)
    }

    private func mountBackground(sc: CGFloat) {
        let wallpaper       = SKSpriteNode(imageNamed: "bg_main")
        wallpaper.size      = size
        wallpaper.position  = CGPoint(x: size.width / 2, y: size.height / 2)
        wallpaper.alpha     = theme.backdropAlpha
        wallpaper.zPosition = -1
        addChild(wallpaper)

        let tintLayer       = SKShapeNode(rectOf: size)
        tintLayer.position  = CGPoint(x: size.width / 2, y: size.height / 2)
        tintLayer.fillColor = theme.overlayTint
        tintLayer.strokeColor = .clear
        tintLayer.zPosition = 0
        addChild(tintLayer)
    }

    private func mountResultIcon(sc: CGFloat) {
        let iconNode       = TypographyScale.labelNode(text: theme.resultIcon, size: 76 * sc)
        iconNode.position  = CGPoint(x: size.width / 2, y: size.height * 0.72)
        iconNode.zPosition = 2
        iconNode.alpha     = 0
        iconNode.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.28),
            SKAction.group([
                SKAction.fadeIn(withDuration: 0.38),
                SKAction.sequence([
                    SKAction.scale(to: 1.35, duration: 0.18),
                    SKAction.scale(to: 1.00, duration: 0.18)
                ])
            ])
        ]))
        addChild(iconNode)
    }

    private func mountHeadline(sc: CGFloat) {
        let headline       = TypographyScale.labelNode(
            text:   theme.headlineText,
            size:   34 * sc,
            tint:   theme.headlineTint,
            weight: .headline
        )
        headline.position  = CGPoint(x: size.width / 2, y: size.height * 0.60)
        headline.zPosition = 2
        headline.alpha     = 0
        headline.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.52),
            SKAction.fadeIn(withDuration: 0.32)
        ]))
        addChild(headline)
    }

    private func mountSubtitle(sc: CGFloat) {
        let bodyText = victory
            ? "30 days in the wasteland. A legend."
            : "Day \(chronicle.diurnalIndex) — The wasteland claims another soul."

        let body                = TypographyScale.labelNode(text: bodyText, size: 12 * sc, tint: DesignToken.ashNebula)
        body.position           = CGPoint(x: size.width / 2, y: size.height * 0.53)
        body.zPosition          = 2
        body.numberOfLines      = 2
        body.preferredMaxLayoutWidth = size.width * 0.84
        body.alpha              = 0
        body.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.68),
            SKAction.fadeIn(withDuration: 0.32)
        ]))
        addChild(body)
    }

    private func mountStatPanel(sc: CGFloat) {
        let entries = [
            StatEntry(caption: "DAYS SURVIVED",  value: "\(chronicle.diurnalIndex)"),
            StatEntry(caption: "ZOMBIES SLAIN",  value: "\(chronicle.revenantTally)"),
            StatEntry(caption: "SURVIVORS MET",  value: "\(chronicle.wayfarerTally)"),
            StatEntry(caption: "HP REMAINING",   value: "\(max(0, chronicle.vitality))")
        ]
        let panel = StatCardBuilder(
            entries: entries,
            accent:  theme.statAccentTint,
            border:  theme.panelBorderTint
        ).buildPanel(sceneWidth: size.width, scale: sc)

        panel.position  = CGPoint(x: size.width / 2, y: size.height * 0.36)
        panel.zPosition = 3
        panel.alpha     = 0
        panel.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.82),
            SKAction.fadeIn(withDuration: 0.32)
        ]))
        addChild(panel)
    }

    private func mountButtons(sc: CGFloat) {
        let btnW = 210 * sc
        let btnH = 52 * sc

        let replayBtn = ObsidianButtonNode(
            size:        CGSize(width: btnW, height: btnH),
            title:       "PLAY AGAIN",
            fillColor:   DesignToken.radiantCrimson,
            titleColor:  DesignToken.frostSheen,
            cornerRadius: 26 * sc
        )
        replayBtn.position  = CGPoint(x: size.width / 2, y: size.height * 0.14)
        replayBtn.zPosition = 4
        replayBtn.alpha     = 0
        replayBtn.onTap     = { [weak self] in self?.navigateToCharacterSelect() }
        replayBtn.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            SKAction.fadeIn(withDuration: 0.32)
        ]))
        addChild(replayBtn)

        let homeBtn = ObsidianButtonNode(
            size:        CGSize(width: btnW * 0.68, height: btnH * 0.72),
            title:       "MAIN MENU",
            fillColor:   DesignToken.violetShadow,
            titleColor:  DesignToken.frostSheen,
            cornerRadius: 16 * sc
        )
        homeBtn.position  = CGPoint(x: size.width / 2, y: size.height * 0.07)
        homeBtn.zPosition = 4
        homeBtn.alpha     = 0
        homeBtn.onTap     = { [weak self] in self?.navigateToMainMenu() }
        homeBtn.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.1),
            SKAction.fadeIn(withDuration: 0.32)
        ]))
        addChild(homeBtn)
    }

    // MARK: - Navigation
    private func navigateToCharacterSelect() {
        let dest = ArchetypeVaultScene(size: size)
        dest.scaleMode = scaleMode
        view?.presentScene(dest, transition: SKTransition.fade(withDuration: 0.5))
    }

    private func navigateToMainMenu() {
        let dest = TitleVaultScene(size: size)
        dest.scaleMode = scaleMode
        view?.presentScene(dest, transition: SKTransition.fade(withDuration: 0.5))
    }
}
