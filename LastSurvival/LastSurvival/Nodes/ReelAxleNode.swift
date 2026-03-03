// ReelAxleNode.swift — Single slot reel column

import SpriteKit

class ReelAxleNode: SKNode {

    private let reelSize: CGSize
    private let maskNode: SKCropNode
    private let stripNode: SKNode
    private var iconNodes: [SKSpriteNode] = []
    private(set) var currentGlyph: GlyphVariant = .provender

    private static let glyphAssets: [GlyphVariant: String] = [
        .provender: "icon_slot_food",
        .aquifer:   "icon_slot_water",
        .armament:  "icon_slot_weapon",
        .revenant:  "icon_slot_zombie",
        .wayfarer:  "icon_slot_survivor"
    ]

    init(size: CGSize) {
        self.reelSize = size
        maskNode = SKCropNode()
        stripNode = SKNode()
        super.init()

        // Mask to clip reel content
        let maskShape = SKSpriteNode(color: .white, size: size)
        maskNode.maskNode = maskShape
        addChild(maskNode)
        maskNode.addChild(stripNode)

        // Border frame
        let frame = PaletteForge.makeRoundedPanel(
            size: size,
            cornerRadius: 12,
            fillColor: .clear,
            strokeColor: PaletteForge.cinderGold,
            lineWidth: 2
        )
        addChild(frame)

        // Subtle inner bg
        let bg = SKShapeNode(rectOf: CGSize(width: size.width - 4, height: size.height - 4), cornerRadius: 10)
        bg.fillColor = UIColor(red: 0.06, green: 0.07, blue: 0.10, alpha: 1)
        bg.strokeColor = .clear
        bg.zPosition = -1
        addChild(bg)

        buildStrip(glyph: .provender)
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    private func iconSize() -> CGSize {
        let s = min(reelSize.width, reelSize.height) * 0.72
        return CGSize(width: s, height: s)
    }

    private func buildStrip(glyph: GlyphVariant) {
        stripNode.removeAllChildren()
        iconNodes.removeAll()
        // Build a strip of 8 random icons ending with target glyph
        var glyphs = GlyphVariant.allCases.shuffled()
        // Ensure target is last
        glyphs.removeAll { $0 == glyph }
        glyphs.append(glyph)
        // Pad to 8
        while glyphs.count < 8 {
            glyphs.insert(GlyphVariant.allCases.randomElement()!, at: 0)
        }

        let iSize = iconSize()
        let spacing = reelSize.height * 1.05
        for (i, g) in glyphs.enumerated() {
            let assetName = ReelAxleNode.glyphAssets[g] ?? "icon_slot_food"
            let sprite = SKSpriteNode(imageNamed: assetName)
            sprite.size = iSize
            // Position from top: index 0 at top, last at bottom visible
            sprite.position = CGPoint(x: 0, y: CGFloat(glyphs.count - 1 - i) * spacing)
            stripNode.addChild(sprite)
            iconNodes.append(sprite)
        }
        // Start strip above visible area
        stripNode.position = CGPoint(x: 0, y: -CGFloat(glyphs.count - 1) * spacing)
    }

    /// Spin animation, calls completion when done
    func spinTo(glyph: GlyphVariant, delay: TimeInterval = 0, completion: @escaping () -> Void) {
        currentGlyph = glyph
        buildStrip(glyph: glyph)

        let totalGlyphs = iconNodes.count
        let spacing = reelSize.height * 1.05
        let totalDistance = CGFloat(totalGlyphs - 1) * spacing

        // Reset position
        stripNode.position = CGPoint(x: 0, y: -totalDistance + spacing * CGFloat(totalGlyphs - 1))

        let wait = SKAction.wait(forDuration: delay)
        // Fast scroll then ease to final
        let fastScroll = SKAction.moveBy(x: 0, y: -(totalDistance * 0.7), duration: 0.35)
        fastScroll.timingMode = .easeIn
        let slowScroll = SKAction.moveBy(x: 0, y: -(totalDistance * 0.3), duration: 0.45)
        slowScroll.timingMode = .easeOut

        let seq = SKAction.sequence([wait, fastScroll, slowScroll, SKAction.run { completion() }])
        stripNode.run(seq)
    }
}
