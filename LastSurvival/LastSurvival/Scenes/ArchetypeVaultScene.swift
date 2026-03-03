// ArchetypeVaultScene.swift — VestibuleClaspScene: character selection (refactored)

import SpriteKit

// MARK: - CharacterCardViewModel: view-model derived from a WayfareBlueprint
private struct CharacterCardViewModel {
    let caste:        VocationCaste
    let displayName:  String
    let roleTag:      String
    let portraitName: String
    let accentColor:  UIColor
    let startHP:      Int
    let startFood:    Int
    let startWater:   Int
    let startWeapon:  Int
    let passive:      String

    static func from(caste: VocationCaste) -> CharacterCardViewModel {
        let bp = WayfareBlueprint.fromCaste(caste)
        let roleMap: [VocationCaste: String] = [.salver: "MEDIC", .pikeman: "COMBAT", .tinker: "TECH"]
        let colorMap: [VocationCaste: UIColor] = [
            .salver:  DesignToken.phosphorLime,
            .pikeman: DesignToken.vermillionAlert,
            .tinker:  DesignToken.ceruleanVolt
        ]
        return CharacterCardViewModel(
            caste:        caste,
            displayName:  bp.sobriquet.uppercased(),
            roleTag:      roleMap[caste] ?? "",
            portraitName: bp.effigyAsset,
            accentColor:  colorMap[caste] ?? DesignToken.frostSheen,
            startHP:      5 + bp.ichorBonus,
            startFood:    2 + bp.mannaBonus,
            startWater:   2,
            startWeapon:  max(0, 1 + bp.falchionBonus),
            passive:      bp.latentAptitude
        )
    }
}

// MARK: - SelectionRingController: manages the glowing selection ring per card
private class SelectionRingController {
    private var rings: [VocationCaste: SKShapeNode] = [:]

    func register(ring: SKShapeNode, for caste: VocationCaste) {
        rings[caste] = ring
    }

    func activate(_ caste: VocationCaste) {
        guard let target = rings[caste] else { return }
        target.alpha     = 1
        target.glowWidth = 4
        target.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.5, duration: 0.6),
            SKAction.fadeAlpha(to: 1.0, duration: 0.6)
        ])))
    }

    func deactivate(_ caste: VocationCaste) {
        guard let target = rings[caste] else { return }
        target.removeAllActions()
        target.alpha     = 0
        target.glowWidth = 0
    }
}

// MARK: - VestibuleClaspScene: character selection screen
class VestibuleClaspScene: SKScene {

    private var selectedCaste: VocationCaste = .salver
    private var cardNodeMap:   [VocationCaste: SKNode] = [:]
    private var cardBoundsMap: [VocationCaste: CGRect] = [:]
    private let ringController = SelectionRingController()
    private var currentDetailPanel: SKNode?

    override func didMove(to view: SKView) {
        backgroundColor = DesignToken.cosmicInk
        buildScene()
    }

    // MARK: - Scene construction

    private func buildScene() {
        let sc = size.calibration
        mountBackground(sc: sc)
        mountHeader(sc: sc)
        mountCharacterGrid(sc: sc)
        buildDetailPanel(sc: sc)
        mountConfirmButton(sc: sc)
    }

    private func mountBackground(sc: CGFloat) {
        let backdrop      = SKSpriteNode(imageNamed: "bg_main")
        backdrop.size     = size
        backdrop.position = CGPoint(x: size.width / 2, y: size.height / 2)
        backdrop.alpha    = 0.14
        backdrop.zPosition = -1
        addChild(backdrop)

        let dimFill = UIColor(red: 0.04, green: 0.02, blue: 0.16, alpha: 0.65)
        let dimLayer       = SKShapeNode(rectOf: size)
        dimLayer.position  = CGPoint(x: size.width / 2, y: size.height / 2)
        dimLayer.fillColor = dimFill
        dimLayer.strokeColor = .clear
        dimLayer.zPosition = 0
        addChild(dimLayer)
    }

    private func mountHeader(sc: CGFloat) {
        let safeTop  = view?.safeAreaInsets.top ?? 44
        let barH     = 46 * sc
        let barCenterY = size.height - safeTop - barH / 2

        let headerBar       = SKShapeNode(rectOf: CGSize(width: size.width, height: barH))
        headerBar.position  = CGPoint(x: size.width / 2, y: barCenterY)
        headerBar.fillColor = UIColor(red: 0.06, green: 0.03, blue: 0.18, alpha: 0.92)
        headerBar.strokeColor = .clear
        headerBar.zPosition = 1
        addChild(headerBar)

        let separator = GeometryForge.dividerLine(span: size.width, tint: DesignToken.radiantCrimson, opacity: 0.45)
        separator.position  = CGPoint(x: size.width / 2, y: barCenterY - barH / 2)
        separator.zPosition = 2
        addChild(separator)

        let backBtn = ClaviculaNodelet(
            size:        CGSize(width: 72 * sc, height: 34 * sc),
            title:       "BACK",
            fillColor:   DesignToken.violetShadow,
            titleColor:  DesignToken.frostSheen,
            cornerRadius: 8 * sc
        )
        backBtn.position  = CGPoint(x: 16 * sc + 36 * sc, y: barCenterY)
        backBtn.zPosition = 4
        backBtn.onImpact  = { [weak self] in self?.returnToMenu() }
        addChild(backBtn)

        let headerTitle = TypographyScale.labelNode(
            text:   "CHOOSE SURVIVOR",
            size:   14 * sc,
            tint:   DesignToken.ceruleanVolt,
            weight: .headline
        )
        headerTitle.position  = CGPoint(x: size.width / 2, y: barCenterY)
        headerTitle.zPosition = 2
        addChild(headerTitle)
    }

    private func mountCharacterGrid(sc: CGFloat) {
        let allCastes: [VocationCaste] = [.salver, .pikeman, .tinker]
        let gutterSize:  CGFloat = 10 * sc
        let sidePadding: CGFloat = 12 * sc
        let cardWidth  = (size.width - sidePadding * 2 - gutterSize * 2) / 3
        let cardHeight = cardWidth * 1.80
        let gridCenterY: CGFloat = size.height * 0.555
        let firstCardX = sidePadding + cardWidth / 2

        allCastes.enumerated().forEach { colIndex, caste in
            let viewModel = CharacterCardViewModel.from(caste: caste)
            let cardSize  = CGSize(width: cardWidth, height: cardHeight)
            let cardX     = firstCardX + CGFloat(colIndex) * (cardWidth + gutterSize)

            let (cardNode, ring) = buildCard(viewModel: viewModel, size: cardSize, scale: sc)
            cardNode.position  = CGPoint(x: cardX, y: gridCenterY)
            cardNode.zPosition = 2
            addChild(cardNode)

            // Register for later lookup
            cardNodeMap[caste]   = cardNode
            cardBoundsMap[caste] = CGRect(x: cardX - cardWidth / 2,
                                          y: gridCenterY - cardHeight / 2,
                                          width: cardWidth, height: cardHeight)

            // Activate ring if this is the default selection
            ringController.register(ring: ring, for: caste)
            if caste == selectedCaste { ringController.activate(caste) }

            // Staggered fade-in
            cardNode.alpha = 0
            cardNode.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.10 * Double(colIndex)),
                SKAction.fadeIn(withDuration: 0.28)
            ]))
        }
    }

    // Builds a character card node for a given view model
    private func buildCard(viewModel: CharacterCardViewModel, size: CGSize, scale sc: CGFloat) -> (SKNode, SKShapeNode) {
        let container = SKNode()

        // Card background
        let cardBg = GeometryForge.panelNode(
            size:        size,
            cutDepth:    12 * sc,
            fill:        DesignToken.obsidianVeil,
            stroke:      DesignToken.violetShadow,
            strokeWidth: 1.5
        )
        container.addChild(cardBg)

        // Selection ring (slightly larger than card)
        let ringInset: CGFloat = 4
        let ringBounds = CGRect(
            x: -size.width / 2 - ringInset,
            y: -size.height / 2 - ringInset,
            width:  size.width  + ringInset * 2,
            height: size.height + ringInset * 2
        )
        let ringPath = GeometryForge.chamferedOutline(bounds: ringBounds, cutDepth: 14 * sc)
        let ring     = SKShapeNode(path: ringPath)
        ring.strokeColor = DesignToken.radiantCrimson
        ring.fillColor   = .clear
        ring.lineWidth   = 2.5
        ring.glowWidth   = 0
        ring.zPosition   = 5
        ring.alpha        = 0
        container.addChild(ring)

        // Portrait image
        let portrait      = SKSpriteNode(imageNamed: viewModel.portraitName)
        portrait.size     = CGSize(width: size.width * 0.74, height: size.width * 0.74)
        portrait.position = CGPoint(x: 0, y: size.height * 0.13)
        container.addChild(portrait)

        // Character name
        let nameLabel = TypographyScale.labelNode(
            text:   viewModel.displayName,
            size:   10 * sc,
            tint:   viewModel.accentColor,
            weight: .headline
        )
        nameLabel.position = CGPoint(x: 0, y: -size.height * 0.30)
        container.addChild(nameLabel)

        // Role tag
        let roleLabel = TypographyScale.labelNode(
            text: viewModel.roleTag,
            size: 8 * sc,
            tint: DesignToken.ashNebula
        )
        roleLabel.position = CGPoint(x: 0, y: -size.height * 0.41)
        container.addChild(roleLabel)

        return (container, ring)
    }

    private func buildDetailPanel(sc: CGFloat) {
        currentDetailPanel?.removeFromParent()
        let viewModel = CharacterCardViewModel.from(caste: selectedCaste)
        let panelW    = size.width - 28 * sc
        let panelH: CGFloat = 112 * sc

        let panel = GeometryForge.panelNode(
            size:        CGSize(width: panelW, height: panelH),
            cutDepth:    10,
            fill:        DesignToken.vaultSurface,
            stroke:      DesignToken.ceruleanVolt.withAlphaComponent(0.5),
            strokeWidth: 1.5
        )
        panel.position  = CGPoint(x: size.width / 2, y: size.height * 0.225)
        panel.zPosition = 3
        addChild(panel)
        currentDetailPanel = panel

        // Four stat columns: HP / FOOD / WATER / WEAPON
        let statPairs: [(String, Int)] = [
            ("HP",     viewModel.startHP),
            ("FOOD",   viewModel.startFood),
            ("WATER",  viewModel.startWater),
            ("WEAPON", viewModel.startWeapon)
        ]
        let columnWidth = panelW / CGFloat(statPairs.count)
        statPairs.enumerated().forEach { colIdx, pair in
            let (label, value) = pair
            let xPos = -panelW / 2 + columnWidth * (CGFloat(colIdx) + 0.5)

            let valueNode = TypographyScale.labelNode(
                text:   "\(value)",
                size:   22 * sc,
                tint:   DesignToken.radiantCrimson,
                weight: .headline
            )
            valueNode.position = CGPoint(x: xPos, y: panelH * 0.15)
            panel.addChild(valueNode)

            let labelNode = TypographyScale.labelNode(
                text: label,
                size: 8 * sc,
                tint: DesignToken.ashNebula
            )
            labelNode.position = CGPoint(x: xPos, y: -panelH * 0.08)
            panel.addChild(labelNode)
        }

        // Divider between stats and passive
        let statDivider = GeometryForge.dividerLine(span: panelW * 0.88, tint: DesignToken.ceruleanVolt, opacity: 0.25)
        statDivider.position = CGPoint(x: 0, y: -panelH * 0.22)
        panel.addChild(statDivider)

        // Passive ability text
        let passiveNode = TypographyScale.labelNode(
            text:   "PASSIVE: \(viewModel.passive)",
            size:   10 * sc,
            tint:   DesignToken.phosphorLime
        )
        passiveNode.position            = CGPoint(x: 0, y: -panelH * 0.36)
        passiveNode.numberOfLines       = 2
        passiveNode.preferredMaxLayoutWidth = panelW - 20 * sc
        panel.addChild(passiveNode)
    }

    // MARK: - Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touchPoint = touches.first?.location(in: self) else { return }
        for (caste, bounds) in cardBoundsMap where bounds.contains(touchPoint) {
            handleSelection(tapped: caste)
            break
        }
    }

    private func handleSelection(tapped caste: VocationCaste) {
        guard caste != selectedCaste else { return }

        // Deactivate previous ring
        ringController.deactivate(selectedCaste)

        // Update selection
        selectedCaste = caste

        // Activate new ring
        ringController.activate(caste)

        // Bounce animation on newly selected card
        cardNodeMap[caste]?.run(SKAction.sequence([
            SKAction.scale(to: 0.94, duration: 0.07),
            SKAction.scale(to: 1.00, duration: 0.07)
        ]))

        // Refresh detail panel
        buildDetailPanel(sc: size.calibration)
    }

    // MARK: - Navigation

    private func launchGame() {
        let blueprint = WayfareBlueprint.fromCaste(selectedCaste)
        let grimoire  = VespersGrimoire(archetype: blueprint)
        let arena     = OublietteSpinScene(size: size, grimoire: grimoire)
        arena.scaleMode = scaleMode
        view?.presentScene(arena, transition: SKTransition.push(with: .left, duration: 0.4))
    }

    private func returnToMenu() {
        let menu = HarbingerDuskScene(size: size)
        menu.scaleMode = scaleMode
        view?.presentScene(menu, transition: SKTransition.push(with: .right, duration: 0.35))
    }

    private func mountConfirmButton(sc: CGFloat) {
        let confirmBtn = ClaviculaNodelet(
            size:        CGSize(width: 210 * sc, height: 52 * sc),
            title:       "CONFIRM",
            fillColor:   DesignToken.radiantCrimson,
            titleColor:  DesignToken.frostSheen,
            cornerRadius: 26 * sc
        )
        confirmBtn.position  = CGPoint(x: size.width / 2, y: size.height * 0.09)
        confirmBtn.zPosition = 4
        confirmBtn.onImpact  = { [weak self] in self?.launchGame() }
        addChild(confirmBtn)
    }

    // Legacy aliases for call-site compat
    private func commenceOubliette() { launchGame() }
    private func retrocede()         { returnToMenu() }
    private func claspCard(_ c: VocationCaste) { handleSelection(tapped: c) }
}

typealias ArchetypeVaultScene = VestibuleClaspScene
