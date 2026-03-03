// ProvisionsManifestNode.swift — TabulaVerdure: HUD resource panel (refactored)

import SpriteKit

// MARK: - HUDLayout: relative position offsets for all HUD sub-elements
private struct HUDLayout {
    let scale: CGFloat
    let totalWidth: CGFloat
    let panelHeight: CGFloat

    // Y positions as fractions of panel height
    var topRowY:      CGFloat { panelHeight *  0.36 }
    var healthBarY:   CGFloat { panelHeight *  0.06 }
    var resourceRowY: CGFloat { panelHeight * -0.30 }

    // Health bar dimensions
    var barSpan:      CGFloat { totalWidth * 0.82 }
    var segmentGap:   CGFloat { 3 * scale }
    var segmentHeight: CGFloat { 11 * scale }

    // Resource column spacing
    var colSpacing: CGFloat { totalWidth * 0.22 }
}

// MARK: - HealthBarRenderer: manages HP segment nodes and color logic
private class HealthBarRenderer {
    private var segments: [SKShapeNode] = []
    private var hpLabel: SKLabelNode!
    private let totalSegments: Int = 10

    // Populate segments into the given parent node using layout metrics
    func buildSegments(into parent: SKNode, layout: HUDLayout) {
        segments.removeAll()

        let segW = (layout.barSpan - layout.segmentGap * CGFloat(totalSegments - 1)) / CGFloat(totalSegments)
        let segH = layout.segmentHeight

        (0..<totalSegments).forEach { index in
            let xOffset = -layout.barSpan / 2 + segW / 2 + CGFloat(index) * (segW + layout.segmentGap)
            let segBounds = CGRect(x: -segW / 2, y: -segH / 2, width: segW, height: segH)
            let segPath   = GeometryForge.chamferedOutline(bounds: segBounds, cutDepth: 2)
            let seg       = SKShapeNode(path: segPath)
            seg.fillColor   = DesignToken.phosphorLime
            seg.strokeColor = .clear
            seg.position    = CGPoint(x: xOffset, y: layout.healthBarY)
            parent.addChild(seg)
            segments.append(seg)
        }

        // HP text label above the bar
        hpLabel = TypographyScale.labelNode(
            text: "HP  5 / 10",
            size: 9 * layout.scale,
            tint: DesignToken.frostSheen.withAlphaComponent(0.7),
            weight: .body
        )
        hpLabel.position = CGPoint(x: 0, y: layout.healthBarY + layout.segmentHeight + 3 * layout.scale)
        parent.addChild(hpLabel)
    }

    // Update segment colors and HP label based on current HP ratio
    func update(current hp: Int, maximum maxHP: Int) {
        let ratio  = CGFloat(hp) / CGFloat(max(1, maxHP))
        let filled = max(0, min(totalSegments, Int(round(ratio * CGFloat(totalSegments)))))

        // Choose fill color based on HP threshold
        let activeFill: UIColor = {
            if ratio > 0.5  { return DesignToken.phosphorLime }
            if ratio > 0.25 { return DesignToken.ceruleanVolt }
            return DesignToken.vermillionAlert
        }()
        let warningGlow: CGFloat = ratio <= 0.3 ? 2 : 0
        let emptyFill = UIColor(white: 0.12, alpha: 1)

        segments.enumerated().forEach { index, seg in
            if index < filled {
                seg.fillColor = activeFill
                seg.glowWidth = warningGlow
            } else {
                seg.fillColor = emptyFill
                seg.glowWidth = 0
            }
        }

        hpLabel.text = "HP  \(hp) / \(maxHP)"
    }
}

// MARK: - ResourceIndicator: icon + mutable count label composite
private class ResourceIndicator {
    let iconSprite: SKSpriteNode
    let countLabel: SKLabelNode

    init(assetName: String, iconSize: CGSize, labelSize: CGFloat, labelOffset: CGFloat, xPos: CGFloat, rowY: CGFloat) {
        iconSprite          = SKSpriteNode(imageNamed: assetName)
        iconSprite.size     = iconSize
        iconSprite.position = CGPoint(x: xPos, y: rowY)

        countLabel = TypographyScale.labelNode(
            text: "0",
            size: labelSize,
            tint: DesignToken.ceruleanVolt,
            weight: .headline
        )
        countLabel.position = CGPoint(x: xPos, y: rowY - labelOffset)
    }

    func attach(to parent: SKNode) {
        parent.addChild(iconSprite)
        parent.addChild(countLabel)
    }

    func updateCount(_ value: Int) {
        countLabel.text = "\(value)"
    }
}

// MARK: - TabulaVerdure: assembled HUD panel
class TabulaVerdure: SKNode {

    // MARK: Sub-components
    private let healthRenderer  = HealthBarRenderer()
    private var foodIndicator:   ResourceIndicator!
    private var waterIndicator:  ResourceIndicator!
    private var weaponIndicator: ResourceIndicator!
    private var survivorIndicator: ResourceIndicator!

    // MARK: Day / weather labels
    private var dayLabel:     SKLabelNode!
    private var weatherIcon:  SKSpriteNode!
    private var weatherLabel: SKLabelNode!

    // MARK: Layout
    private let metrics: DisplayMetrics
    private let layout:  HUDLayout

    init(sceneSize: CGSize) {
        let dm = DisplayMetrics(screenSize: sceneSize)
        let panelW = sceneSize.width - 24 * dm.factor
        let panelH: CGFloat = 114 * dm.factor

        self.metrics = dm
        self.layout  = HUDLayout(
            scale:       dm.factor,
            totalWidth:  panelW,
            panelHeight: panelH
        )

        super.init()

        buildBackground()
        buildStatusRow()
        buildHealthBar()
        buildResourceRow()
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) not implemented") }

    // MARK: - Four-phase construction

    private func buildBackground() {
        let panelSize = CGSize(width: layout.totalWidth, height: layout.panelHeight)
        let bg = GeometryForge.panelNode(
            size: panelSize,
            cutDepth: 10,
            fill: DesignToken.vaultSurface,
            stroke: DesignToken.radiantCrimson,
            strokeWidth: 2
        )
        bg.glowWidth = 1.5
        addChild(bg)

        // Aqua corner brackets on the background panel
        GeometryForge.attachCornerBrackets(
            to: bg,
            covering: panelSize,
            armLength: 10,
            tint: DesignToken.ceruleanVolt,
            thickness: 1.5
        )
    }

    private func buildStatusRow() {
        let sc  = metrics.factor
        let row1Y = layout.topRowY

        // Day counter label (left side)
        dayLabel = TypographyScale.labelNode(
            text: "DAY 1",
            size: 13 * sc,
            tint: DesignToken.radiantCrimson,
            weight: .headline
        )
        dayLabel.position = CGPoint(x: -layout.totalWidth * 0.34, y: row1Y)
        addChild(dayLabel)

        // Weather icon (center-left)
        weatherIcon      = SKSpriteNode(imageNamed: "icon_weather_sunny")
        weatherIcon.size = CGSize(width: 20 * sc, height: 20 * sc)
        weatherIcon.position = CGPoint(x: layout.totalWidth * 0.12, y: row1Y)
        addChild(weatherIcon)

        // Weather text label (center-right)
        weatherLabel = TypographyScale.labelNode(
            text: "SUNNY",
            size: 10 * sc,
            tint: DesignToken.ceruleanVolt,
            weight: .headline
        )
        weatherLabel.position = CGPoint(x: layout.totalWidth * 0.28, y: row1Y)
        weatherLabel.horizontalAlignmentMode = .center
        addChild(weatherLabel)
    }

    private func buildHealthBar() {
        healthRenderer.buildSegments(into: self, layout: layout)
    }

    private func buildResourceRow() {
        let sc         = metrics.factor
        let iconSize   = CGSize(width: 18 * sc, height: 18 * sc)
        let labelSize  = 12 * sc
        let labelDrop  = 15 * sc
        let rowY       = layout.resourceRowY
        let col        = layout.colSpacing

        // Define the four resource slots: (assetName, x-column multiplier)
        let resourceDefs: [(String, CGFloat)] = [
            ("icon_slot_food",     -col * 1.5),
            ("icon_slot_water",    -col * 0.5),
            ("icon_slot_weapon",    col * 0.5),
            ("icon_slot_survivor",  col * 1.5)
        ]

        let indicators = resourceDefs.map { assetName, xPos in
            ResourceIndicator(
                assetName:   assetName,
                iconSize:    iconSize,
                labelSize:   labelSize,
                labelOffset: labelDrop,
                xPos:        xPos,
                rowY:        rowY
            )
        }
        indicators.forEach { $0.attach(to: self) }

        // Assign to named properties for later updates
        foodIndicator     = indicators[0]
        waterIndicator    = indicators[1]
        weaponIndicator   = indicators[2]
        survivorIndicator = indicators[3]
    }

    // MARK: - Update API

    func replenish(grimoire: VespersGrimoire) {
        // Day and weather
        dayLabel.text            = "DAY \(grimoire.solsticeCount)"
        weatherIcon.texture      = SKTexture(imageNamed: grimoire.etherClimate.sigillumAsset)
        weatherLabel.text        = grimoire.etherClimate.appellative.uppercased()

        // Health bar
        healthRenderer.update(current: grimoire.ichor, maximum: grimoire.maxIchor)

        // Resource counts
        foodIndicator.updateCount(grimoire.mannaCache)
        waterIndicator.updateCount(grimoire.brineCache)
        weaponIndicator.updateCount(grimoire.falchionCache)
        survivorIndicator.updateCount(grimoire.pilgrimCount)
    }
}

// MARK: - Backward-compat alias
typealias ProvisionsManifestNode = TabulaVerdure

extension TabulaVerdure {
    func refresh(chronicle: VespersGrimoire) { replenish(grimoire: chronicle) }
}
