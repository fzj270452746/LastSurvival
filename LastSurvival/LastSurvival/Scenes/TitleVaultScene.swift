// TitleVaultScene.swift — HarbingerDuskScene: title / main menu (refactored)

import SpriteKit

// MARK: - MenuItemDescriptor: declarative button specification
private struct MenuItemDescriptor {
    let title:      String
    let fillColor:  UIColor
    let textColor:  UIColor
    let size:       CGSize
    let yFraction:  CGFloat   // Y position as fraction of scene height
    let action:     () -> Void
}

// MARK: - BackgroundWeaver: builds ambient decorative background
private class BackgroundWeaver {
    private let sceneSize: CGSize
    private let scale: CGFloat

    init(sceneSize: CGSize, scale: CGFloat) {
        self.sceneSize = sceneSize
        self.scale     = scale
    }

    func build(into scene: SKScene) {
        mountBackdropImage(into: scene)
        mountDimOverlay(into: scene)
        mountGridLines(into: scene, count: 8)
    }

    private func mountBackdropImage(into scene: SKScene) {
        let sprite       = SKSpriteNode(imageNamed: "bg_main")
        sprite.size      = sceneSize
        sprite.position  = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
        sprite.alpha     = 0.18
        sprite.zPosition = -1
        scene.addChild(sprite)
    }

    private func mountDimOverlay(into scene: SKScene) {
        let tint = UIColor(red: 0.04, green: 0.02, blue: 0.14, alpha: 0.72)
        let overlay       = SKShapeNode(rectOf: sceneSize)
        overlay.position  = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
        overlay.fillColor = tint
        overlay.strokeColor = .clear
        overlay.zPosition  = 0
        scene.addChild(overlay)
    }

    private func mountGridLines(into scene: SKScene, count: Int) {
        (0..<count).forEach { index in
            let yPos = sceneSize.height * CGFloat(index) / CGFloat(count)
            let path = CGMutablePath()
            path.move(to:    CGPoint(x: 0, y: yPos))
            path.addLine(to: CGPoint(x: sceneSize.width, y: yPos))
            let gridLine = SKShapeNode(path: path)
            gridLine.strokeColor = DesignToken.radiantCrimson.withAlphaComponent(0.04)
            gridLine.lineWidth   = 1
            gridLine.zPosition   = 0
            scene.addChild(gridLine)
        }
    }
}

// MARK: - StatsDisplay: best-run statistics footer
private class StatsDisplay {
    private let archive = AnnalsDepository.shared
    private let scale: CGFloat

    init(scale: CGFloat) { self.scale = scale }

    func build(into scene: SKScene, sceneSize: CGSize) {
        guard archive.totalExpeditions > 0 else { return }
        let stats  = archive.statistics
        let blurb  = "BEST: \(stats.bestDaysCount) DAYS  |  RUNS: \(stats.totalRunCount)  |  VICTORIES: \(stats.victoryCount)"
        let label  = TypographyScale.labelNode(
            text:   blurb,
            size:   9 * scale,
            tint:   DesignToken.ashNebula
        )
        label.position  = CGPoint(x: sceneSize.width / 2, y: sceneSize.height * 0.10)
        label.zPosition = 2
        scene.addChild(label)
    }
}

// MARK: - HarbingerDuskScene: main menu
class HarbingerDuskScene: SKScene {

    override func didMove(to view: SKView) {
        backgroundColor = DesignToken.cosmicInk
        assembleScene()
    }

    private func assembleScene() {
        let sc = size.calibration

        // Background layer
        BackgroundWeaver(sceneSize: size, scale: sc).build(into: self)

        // Branding region
        assembleBranding(sc: sc)

        // Menu buttons (data-driven)
        assembleMenuButtons(sc: sc)

        // Statistics footer
        StatsDisplay(scale: sc).build(into: self, sceneSize: size)

        // Version label
        let verLabel  = TypographyScale.labelNode(
            text: "v1.0",
            size: 9 * sc,
            tint: DesignToken.ashNebula.withAlphaComponent(0.5)
        )
        verLabel.position  = CGPoint(x: size.width / 2, y: size.height * 0.05)
        verLabel.zPosition = 2
        addChild(verLabel)
    }

    // MARK: - Branding assembly

    private func assembleBranding(sc: CGFloat) {
        // Top separator
        let topSep = GeometryForge.dividerLine(span: size.width * 0.85, tint: DesignToken.radiantCrimson, opacity: 0.5)
        topSep.position  = CGPoint(x: size.width / 2, y: size.height * 0.82)
        topSep.zPosition = 2
        addChild(topSep)

        // Tag line with blink animation
        let tagLabel = TypographyScale.labelNode(
            text:   "// SLOT SURVIVAL SYSTEM v1.0",
            size:   10 * sc,
            tint:   DesignToken.ceruleanVolt.withAlphaComponent(0.85)
        )
        tagLabel.position  = CGPoint(x: size.width / 2, y: size.height * 0.79)
        tagLabel.zPosition = 2
        tagLabel.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.35, duration: 1.5),
            SKAction.fadeAlpha(to: 1.0,  duration: 1.5)
        ])))
        addChild(tagLabel)

        // Primary title word
        let wordLast = TypographyScale.labelNode(
            text:   "LAST",
            size:   64 * sc,
            tint:   DesignToken.radiantCrimson,
            weight: .headline
        )
        wordLast.position  = CGPoint(x: size.width / 2, y: size.height * 0.70)
        wordLast.zPosition = 2
        addChild(wordLast)

        // Secondary title word
        let wordSurvival = TypographyScale.labelNode(
            text:   "SURVIVAL",
            size:   36 * sc,
            tint:   DesignToken.frostSheen,
            weight: .headline
        )
        wordSurvival.position  = CGPoint(x: size.width / 2, y: size.height * 0.62)
        wordSurvival.zPosition = 2
        addChild(wordSurvival)

        // Blue sub-divider
        let subDiv = GeometryForge.dividerLine(span: size.width * 0.65, tint: DesignToken.ceruleanVolt, opacity: 0.45)
        subDiv.position  = CGPoint(x: size.width / 2, y: size.height * 0.58)
        subDiv.zPosition = 2
        addChild(subDiv)

        // Flavor text
        let flavorText = TypographyScale.labelNode(
            text: "Spin the reels. Survive the apocalypse.",
            size: 12 * sc,
            tint: DesignToken.ashNebula
        )
        flavorText.position  = CGPoint(x: size.width / 2, y: size.height * 0.53)
        flavorText.zPosition = 2
        addChild(flavorText)

        // Entrance cascade: title, subtitle, flavor text
        let entranceTargets: [SKNode] = [wordLast, wordSurvival, flavorText]
        entranceTargets.enumerated().forEach { index, node in
            node.alpha = 0
            node.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.25 + Double(index) * 0.12),
                SKAction.group([
                    SKAction.fadeIn(withDuration: 0.38),
                    SKAction.moveBy(x: 0, y: 10 * sc, duration: 0.38)
                ])
            ]))
        }
    }

    // MARK: - Menu button assembly (data-driven)

    private func assembleMenuButtons(sc: CGFloat) {
        let primaryW = 230 * sc
        let primaryH = 56 * sc
        let secondaryW = (size.width - 32 * sc) / 2
        let secondaryH = 42 * sc

        // Declare all buttons as descriptors
        let descriptors: [MenuItemDescriptor] = [
            MenuItemDescriptor(
                title:     "START GAME",
                fillColor: DesignToken.radiantCrimson,
                textColor: DesignToken.frostSheen,
                size:      CGSize(width: primaryW, height: primaryH),
                yFraction: 0.40,
                action:    { [weak self] in self?.navigateToCharacterSelect() }
            ),
            MenuItemDescriptor(
                title:     "HOW TO PLAY",
                fillColor: DesignToken.cosmicInk,
                textColor: DesignToken.ceruleanVolt,
                size:      CGSize(width: primaryW, height: secondaryH),
                yFraction: 0.18,
                action:    { [weak self] in self?.navigateToTutorial() }
            )
        ]

        // Create primary + how-to buttons (centered)
        var spawnedNodes: [SKNode] = []
        descriptors.forEach { descriptor in
            let btn = ClaviculaNodelet(
                size:        descriptor.size,
                title:       descriptor.title,
                fillColor:   descriptor.fillColor,
                titleColor:  descriptor.textColor,
                cornerRadius: descriptor.size.height * 0.5
            )
            btn.position  = CGPoint(x: size.width / 2, y: size.height * descriptor.yFraction)
            btn.zPosition = 3
            btn.onImpact  = descriptor.action
            addChild(btn)
            spawnedNodes.append(btn)
        }

        // Pulse animation on START button
        spawnedNodes.first?.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.04, duration: 1.0),
            SKAction.scale(to: 1.00, duration: 1.0)
        ])))

        // Side-by-side secondary buttons
        let secY = size.height * 0.28

        let historyBtn = ClaviculaNodelet(
            size:        CGSize(width: secondaryW, height: secondaryH),
            title:       "HISTORY",
            fillColor:   DesignToken.violetShadow,
            titleColor:  DesignToken.frostSheen,
            cornerRadius: 10 * sc
        )
        historyBtn.position  = CGPoint(x: 16 * sc + secondaryW / 2, y: secY)
        historyBtn.zPosition = 3
        historyBtn.onImpact  = { [weak self] in self?.navigateToHistory() }
        addChild(historyBtn)
        spawnedNodes.append(historyBtn)

        let achBtn = ClaviculaNodelet(
            size:        CGSize(width: secondaryW, height: secondaryH),
            title:       "ACHIEVEMENTS",
            fillColor:   DesignToken.violetShadow,
            titleColor:  DesignToken.phosphorLime,
            cornerRadius: 10 * sc
        )
        achBtn.position  = CGPoint(x: size.width - 16 * sc - secondaryW / 2, y: secY)
        achBtn.zPosition = 3
        achBtn.onImpact  = { [weak self] in self?.navigateToAchievements() }
        addChild(achBtn)
        spawnedNodes.append(achBtn)

        // Entrance fade-in for all buttons (staggered)
        spawnedNodes.enumerated().forEach { index, node in
            node.alpha = 0
            node.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.25 + Double(index) * 0.12),
                SKAction.fadeIn(withDuration: 0.38)
            ]))
        }
    }

    // MARK: - Navigation helpers

    private func navigateToCharacterSelect() {
        let destination = VestibuleClaspScene(size: size)
        destination.scaleMode = scaleMode
        view?.presentScene(destination, transition: SKTransition.push(with: .left, duration: 0.4))
    }

    private func navigateToHistory() {
        let destination = ChronolithScrollScene(size: size)
        destination.scaleMode = scaleMode
        view?.presentScene(destination, transition: SKTransition.push(with: .left, duration: 0.35))
    }

    private func navigateToAchievements() {
        let destination = PalimpsestGildScene(size: size)
        destination.scaleMode = scaleMode
        view?.presentScene(destination, transition: SKTransition.push(with: .left, duration: 0.35))
    }

    private func navigateToTutorial() {
        let destination = VademecumScrollScene(size: size)
        destination.scaleMode = scaleMode
        view?.presentScene(destination, transition: SKTransition.push(with: .left, duration: 0.35))
    }

    // Legacy navigation aliases
    private func proceedToVestibule()  { navigateToCharacterSelect() }
    private func proceedToChronolith() { navigateToHistory() }
    private func proceedToPalimpsest() { navigateToAchievements() }
    private func proceedToVademecum()  { navigateToTutorial() }
}

typealias TitleVaultScene = HarbingerDuskScene
