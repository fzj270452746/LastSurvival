// AchievementScene.swift — Achievement showcase (refactored)

import SpriteKit

// MARK: - AchievementCardStyle: unlocked vs locked rendering style
private enum AchievementCardStyle {
    case unlocked(date: Date?)
    case locked

    var borderTint: UIColor {
        switch self {
        case .unlocked:
            return DesignToken.phosphorLime.withAlphaComponent(0.60)
        case .locked:
            return DesignToken.violetShadow.withAlphaComponent(0.30)
        }
    }

    var fillTint: UIColor {
        switch self {
        case .unlocked:
            return DesignToken.obsidianVeil
        case .locked:
            return UIColor(red: 0.06, green: 0.04, blue: 0.14, alpha: 0.82)
        }
    }

    var strokeWidth: CGFloat {
        switch self {
        case .unlocked: return 1.5
        case .locked:   return 1.0
        }
    }

    var titleTint: UIColor {
        switch self {
        case .unlocked: return DesignToken.phosphorLime
        case .locked:   return DesignToken.ashNebula.withAlphaComponent(0.45)
        }
    }

    var descriptionTint: UIColor {
        switch self {
        case .unlocked: return DesignToken.frostSheen.withAlphaComponent(0.72)
        case .locked:   return DesignToken.ashNebula.withAlphaComponent(0.28)
        }
    }
}

// MARK: - AchievementGridLayout: 2-column grid positioning
private struct AchievementGridLayout {
    let columnCount:  Int
    let cardWidth:    CGFloat
    let cardHeight:   CGFloat
    let gutterSize:   CGFloat
    let leftEdgeX:    CGFloat

    init(sceneWidth: CGFloat, scale sc: CGFloat, leftPadding: CGFloat = 12) {
        columnCount  = 2
        gutterSize   = 10 * sc
        cardWidth    = (sceneWidth - leftPadding * 2 * sc - gutterSize) / 2
        cardHeight   = 74 * sc
        leftEdgeX    = leftPadding * sc
    }

    // Returns the center-point (x, y) for a card at a given index
    func position(forIndex index: Int, topY: CGFloat) -> CGPoint {
        let col = index % columnCount
        let row = index / columnCount
        let x   = leftEdgeX + cardWidth / 2 + CGFloat(col) * (cardWidth + gutterSize)
        let y   = topY - cardHeight / 2 - CGFloat(row) * (cardHeight + gutterSize)
        return CGPoint(x: x, y: y)
    }

    var cellStride: CGFloat { cardHeight + gutterSize }
}

// MARK: - AchievementScene
class AchievementScene: SKScene {

    override func didMove(to view: SKView) {
        backgroundColor = DesignToken.cosmicInk
        assembleInterface()
    }

    private func assembleInterface() {
        let sc      = size.calibration
        let safeTop = view?.safeAreaInsets.top    ?? 44
        let safeBot = view?.safeAreaInsets.bottom ?? 34

        mountBackground(sc: sc)
        let headerEdgeY = mountHeader(sc: sc, safeTop: safeTop)
        mountAchievementGrid(sc: sc, topY: headerEdgeY - 14 * sc, bottomY: safeBot + 14 * sc)
    }

    private func mountBackground(sc: CGFloat) {
        let wallpaper       = SKSpriteNode(imageNamed: "bg_main")
        wallpaper.size      = size
        wallpaper.position  = CGPoint(x: size.width / 2, y: size.height / 2)
        wallpaper.alpha     = 0.12
        wallpaper.zPosition = -1
        addChild(wallpaper)

        let dim       = SKShapeNode(rectOf: size)
        dim.position  = CGPoint(x: size.width / 2, y: size.height / 2)
        dim.fillColor = UIColor(red: 0.03, green: 0.02, blue: 0.14, alpha: 0.65)
        dim.strokeColor = .clear
        dim.zPosition = 0
        addChild(dim)
    }

    // Returns bottom Y of header
    private func mountHeader(sc: CGFloat, safeTop: CGFloat) -> CGFloat {
        let barH       = 46 * sc
        let barCenterY = size.height - safeTop - barH / 2

        let headerBar       = SKShapeNode(rectOf: CGSize(width: size.width, height: barH))
        headerBar.position  = CGPoint(x: size.width / 2, y: barCenterY)
        headerBar.fillColor = UIColor(red: 0.06, green: 0.03, blue: 0.18, alpha: 0.92)
        headerBar.strokeColor = .clear
        headerBar.zPosition = 1
        addChild(headerBar)

        let divider = GeometryForge.dividerLine(span: size.width, tint: DesignToken.radiantCrimson, opacity: 0.45)
        divider.position  = CGPoint(x: size.width / 2, y: barCenterY - barH / 2)
        divider.zPosition = 2
        addChild(divider)

        let backBtn = ObsidianButtonNode(
            size:        CGSize(width: 72 * sc, height: 34 * sc),
            title:       "BACK",
            fillColor:   DesignToken.violetShadow,
            titleColor:  DesignToken.frostSheen,
            cornerRadius: 8 * sc
        )
        backBtn.position  = CGPoint(x: 16 * sc + 36 * sc, y: barCenterY)
        backBtn.zPosition = 4
        backBtn.onTap     = { [weak self] in self?.returnToMenu() }
        addChild(backBtn)

        // Title with "X/Y" progress in same label
        let registry    = AchievementRegistry.shared
        let progressStr = "\(registry.unlockedCount)/\(registry.all.count)"
        let titleNode   = TypographyScale.labelNode(
            text:   "ACHIEVEMENTS  \(progressStr)",
            size:   13 * sc,
            tint:   DesignToken.ceruleanVolt,
            weight: .headline
        )
        titleNode.position  = CGPoint(x: size.width / 2, y: barCenterY)
        titleNode.zPosition = 2
        addChild(titleNode)

        return barCenterY - barH / 2
    }

    private func mountAchievementGrid(sc: CGFloat, topY: CGFloat, bottomY: CGFloat) {
        let registry = AchievementRegistry.shared
        let all      = registry.all
        let layout   = AchievementGridLayout(sceneWidth: size.width, scale: sc)

        // How many rows fit in the available vertical space
        let visibleRows = Int((topY - bottomY) / layout.cellStride)
        let maxCards    = visibleRows * layout.columnCount
        let displayed   = Array(all.prefix(maxCards))

        displayed.enumerated().forEach { idx, medallion in
            let style: AchievementCardStyle = medallion.isUnlocked
                ? .unlocked(date: medallion.unlockedDate)
                : .locked

            let card     = buildAchievementCard(medallion: medallion, style: style, sc: sc, layout: layout)
            card.position  = layout.position(forIndex: idx, topY: topY)
            card.zPosition = 2
            card.alpha     = 0
            card.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.04 * Double(idx)),
                SKAction.fadeIn(withDuration: 0.20)
            ]))
            addChild(card)
        }
    }

    private func buildAchievementCard(
        medallion: Achievement,
        style: AchievementCardStyle,
        sc: CGFloat,
        layout: AchievementGridLayout
    ) -> SKNode {
        let w    = layout.cardWidth
        let h    = layout.cardHeight
        let root = SKNode()

        let bg = GeometryForge.panelNode(
            size:        CGSize(width: w, height: h),
            cutDepth:    8,
            fill:        style.fillTint,
            stroke:      style.borderTint,
            strokeWidth: style.strokeWidth
        )
        root.addChild(bg)

        // Icon (locked shows padlock emoji)
        let displayIcon = medallion.isUnlocked ? medallion.icon : "🔒"
        let iconNode    = TypographyScale.labelNode(text: displayIcon, size: 20 * sc)
        iconNode.position = CGPoint(x: -w / 2 + 20 * sc, y: 0)
        root.addChild(iconNode)

        let textLeftX   = -w / 2 + 40 * sc
        let textMaxWidth = w - 50 * sc

        // Title
        let titleNode = TypographyScale.labelNode(
            text:   medallion.title,
            size:   10 * sc,
            tint:   style.titleTint,
            weight: .headline
        )
        titleNode.position                = CGPoint(x: textLeftX, y: h * 0.14)
        titleNode.horizontalAlignmentMode = .left
        titleNode.numberOfLines           = 1
        titleNode.preferredMaxLayoutWidth = textMaxWidth
        root.addChild(titleNode)

        // Description
        let descNode = TypographyScale.labelNode(
            text: medallion.description,
            size: 9 * sc,
            tint: style.descriptionTint
        )
        descNode.position                = CGPoint(x: textLeftX, y: -h * 0.20)
        descNode.horizontalAlignmentMode = .left
        descNode.numberOfLines           = 2
        descNode.preferredMaxLayoutWidth = textMaxWidth
        root.addChild(descNode)

        // Unlock date (top-right, only if unlocked)
        if case .unlocked(let date) = style, let unlockDate = date {
            let df = DateFormatter()
            df.dateFormat = "MM/dd"
            let dateNode = TypographyScale.labelNode(
                text: df.string(from: unlockDate),
                size: 8 * sc,
                tint: DesignToken.ceruleanVolt.withAlphaComponent(0.65)
            )
            dateNode.position                = CGPoint(x: w / 2 - 8 * sc, y: h * 0.28)
            dateNode.horizontalAlignmentMode = .right
            root.addChild(dateNode)
        }

        return root
    }

    private func returnToMenu() {
        let menu = TitleVaultScene(size: size)
        menu.scaleMode = scaleMode
        view?.presentScene(menu, transition: SKTransition.push(with: .right, duration: 0.35))
    }

    private func goBack() { returnToMenu() }
}

typealias PalimpsestGildScene = AchievementScene
