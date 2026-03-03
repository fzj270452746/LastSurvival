// ProvisionsManifestNode.swift — HUD resource panel

import SpriteKit

class ProvisionsManifestNode: SKNode {

    private let sc: CGFloat
    private var vitaBar: SKShapeNode!
    private var vitaFill: SKShapeNode!
    private var vitaLabel: SKLabelNode!
    private var dayLabel: SKLabelNode!
    private var weatherIcon: SKSpriteNode!
    private var weatherLabel: SKLabelNode!

    private var foodIcon: SKSpriteNode!
    private var foodLabel: SKLabelNode!
    private var waterIcon: SKSpriteNode!
    private var waterLabel: SKLabelNode!
    private var weaponIcon: SKSpriteNode!
    private var weaponLabel: SKLabelNode!
    private var survivorIcon: SKSpriteNode!
    private var survivorLabel: SKLabelNode!

    private let panelWidth: CGFloat
    private let maxVita: Int = 10

    init(sceneSize: CGSize) {
        sc = sceneSize.adaptiveScale
        panelWidth = sceneSize.width - 24 * sc
        super.init()
        buildPanel()
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    private func buildPanel() {
        let ph: CGFloat = 110 * sc
        let bg = PaletteForge.makeRoundedPanel(
            size: CGSize(width: panelWidth, height: ph),
            cornerRadius: 14 * sc,
            fillColor: PaletteForge.panelBg,
            strokeColor: PaletteForge.cinderGold.withAlphaComponent(0.5),
            lineWidth: 1
        )
        addChild(bg)

        // Day label
        dayLabel = PaletteForge.makeLabel(text: "Day 1", fontSize: 13 * sc, color: PaletteForge.cinderGold, bold: true)
        dayLabel.position = CGPoint(x: -panelWidth * 0.38, y: ph * 0.35)
        addChild(dayLabel)

        // Weather — kept well left of the portrait that sits at the right edge
        weatherIcon = SKSpriteNode(imageNamed: "icon_weather_sunny")
        weatherIcon.size = CGSize(width: 22 * sc, height: 22 * sc)
        weatherIcon.position = CGPoint(x: panelWidth * 0.18, y: ph * 0.35)
        addChild(weatherIcon)

        weatherLabel = PaletteForge.makeLabel(text: "Sunny", fontSize: 11 * sc, color: PaletteForge.ashWhite)
        weatherLabel.position = CGPoint(x: panelWidth * 0.28, y: ph * 0.35)
        weatherLabel.horizontalAlignmentMode = .center
        addChild(weatherLabel)

        // HP bar
        let barW = panelWidth * 0.88
        let barH: CGFloat = 10 * sc
        let barY = ph * 0.08

        let barBg = SKShapeNode(rectOf: CGSize(width: barW, height: barH), cornerRadius: barH/2)
        barBg.fillColor = UIColor(white: 0.2, alpha: 1)
        barBg.strokeColor = .clear
        barBg.position = CGPoint(x: 0, y: barY)
        addChild(barBg)

        vitaFill = SKShapeNode(rectOf: CGSize(width: barW, height: barH), cornerRadius: barH/2)
        vitaFill.fillColor = PaletteForge.jadeTeal
        vitaFill.strokeColor = .clear
        vitaFill.position = CGPoint(x: 0, y: barY)
        addChild(vitaFill)

        vitaLabel = PaletteForge.makeLabel(text: "HP  5 / 10", fontSize: 10 * sc, color: PaletteForge.ashWhite)
        vitaLabel.position = CGPoint(x: 0, y: barY + barH + 3 * sc)
        addChild(vitaLabel)

        // Resource row
        let iconSz = CGSize(width: 20 * sc, height: 20 * sc)
        let rowY = -(ph * 0.28)
        let spacing = panelWidth * 0.22

        foodIcon = SKSpriteNode(imageNamed: "icon_slot_food")
        foodIcon.size = iconSz
        foodIcon.position = CGPoint(x: -spacing * 1.5, y: rowY)
        addChild(foodIcon)
        foodLabel = PaletteForge.makeLabel(text: "2", fontSize: 12 * sc, color: PaletteForge.ashWhite)
        foodLabel.position = CGPoint(x: -spacing * 1.5, y: rowY - 16 * sc)
        addChild(foodLabel)

        waterIcon = SKSpriteNode(imageNamed: "icon_slot_water")
        waterIcon.size = iconSz
        waterIcon.position = CGPoint(x: -spacing * 0.5, y: rowY)
        addChild(waterIcon)
        waterLabel = PaletteForge.makeLabel(text: "2", fontSize: 12 * sc, color: PaletteForge.ashWhite)
        waterLabel.position = CGPoint(x: -spacing * 0.5, y: rowY - 16 * sc)
        addChild(waterLabel)

        weaponIcon = SKSpriteNode(imageNamed: "icon_slot_weapon")
        weaponIcon.size = iconSz
        weaponIcon.position = CGPoint(x: spacing * 0.5, y: rowY)
        addChild(weaponIcon)
        weaponLabel = PaletteForge.makeLabel(text: "1", fontSize: 12 * sc, color: PaletteForge.ashWhite)
        weaponLabel.position = CGPoint(x: spacing * 0.5, y: rowY - 16 * sc)
        addChild(weaponLabel)

        survivorIcon = SKSpriteNode(imageNamed: "icon_slot_survivor")
        survivorIcon.size = iconSz
        survivorIcon.position = CGPoint(x: spacing * 1.5, y: rowY)
        addChild(survivorIcon)
        survivorLabel = PaletteForge.makeLabel(text: "0", fontSize: 12 * sc, color: PaletteForge.ashWhite)
        survivorLabel.position = CGPoint(x: spacing * 1.5, y: rowY - 16 * sc)
        addChild(survivorLabel)
    }

    func refresh(chronicle: VigilChronicle) {
        dayLabel.text = "Day \(chronicle.diurnalIndex)"
        weatherIcon.texture = SKTexture(imageNamed: chronicle.aetherCondition.iconAsset)
        weatherLabel.text = chronicle.aetherCondition.displayName

        // HP bar fill
        let ratio = CGFloat(chronicle.vitality) / CGFloat(chronicle.maxVitality)
        let barW = panelWidth * 0.88
        let barH: CGFloat = 10 * sc
        let fillW = max(barH, barW * ratio)
        let fillPath = UIBezierPath(roundedRect: CGRect(x: -barW/2, y: -barH/2, width: fillW, height: barH), cornerRadius: barH/2)
        vitaFill.path = fillPath.cgPath
        vitaFill.fillColor = ratio > 0.5 ? PaletteForge.jadeTeal : (ratio > 0.25 ? PaletteForge.emberOrange : PaletteForge.bloodRed)
        vitaLabel.text = "HP  \(chronicle.vitality) / \(chronicle.maxVitality)"

        foodLabel.text = "\(chronicle.provenderStock)"
        waterLabel.text = "\(chronicle.aquiferStock)"
        weaponLabel.text = "\(chronicle.armamentStock)"
        survivorLabel.text = "\(chronicle.wayfarerCount)"
    }
}
