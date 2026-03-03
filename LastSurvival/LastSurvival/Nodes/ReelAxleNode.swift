// ReelAxleNode.swift — VortexSpindle: single slot reel column (refactored)

import SpriteKit

// MARK: - SymbolStrip: pure value type for reel symbol layout data
struct SymbolStrip {
    let sequence: [RuneSpecimen]
    let targetIndex: Int       // index of the target specimen in sequence
    let cellSpacing: CGFloat   // vertical distance between symbol centers

    // Asset name mapping for each specimen
    static let assetIndex: [RuneSpecimen: String] = [
        .manna:    "icon_slot_food",
        .brine:    "icon_slot_water",
        .falchion: "icon_slot_weapon",
        .specter:  "icon_slot_zombie",
        .pilgrim:  "icon_slot_survivor"
    ]

    static func assetName(for specimen: RuneSpecimen) -> String {
        assetIndex[specimen] ?? "icon_slot_food"
    }

    // Build a strip that ends with the target specimen at the bottom
    // Fills to at least minLength symbols using random choices
    static func build(targeting target: RuneSpecimen, minLength: Int = 8) -> [RuneSpecimen] {
        // Start with shuffled full set, remove target to place it explicitly at end
        var pool = RuneSpecimen.allCases.shuffled().filter { $0 != target }
        // Pad to fill minLength minus 1 (last slot reserved for target)
        let requiredPadding = max(0, minLength - 1 - pool.count)
        (0..<requiredPadding).forEach { _ in
            pool.insert(RuneSpecimen.allCases.randomElement()!, at: 0)
        }
        // Append target as the final (bottom-most) symbol
        pool.append(target)
        return pool
    }
}

// MARK: - SpinParameters: animation timing configuration
struct SpinParameters {
    var predelay:      TimeInterval
    var accelerateFor: TimeInterval   // fast phase
    var decelerateFor: TimeInterval   // slow (ease-out) phase
    var fastFraction:  CGFloat        // portion of total distance in fast phase

    static let standard = SpinParameters(
        predelay:      0,
        accelerateFor: 0.35,
        decelerateFor: 0.45,
        fastFraction:  0.7
    )

    static func withDelay(_ d: TimeInterval) -> SpinParameters {
        SpinParameters(
            predelay:      d,
            accelerateFor: 0.35,
            decelerateFor: 0.45,
            fastFraction:  0.7
        )
    }
}

// MARK: - MotionPhase: describes each phase of a spin animation
enum MotionPhase {
    case accelerate(distance: CGFloat, duration: TimeInterval)
    case decelerate(distance: CGFloat, duration: TimeInterval)

    func buildAction() -> SKAction {
        switch self {
        case let .accelerate(dist, dur):
            let act = SKAction.moveBy(x: 0, y: -dist, duration: dur)
            act.timingMode = .easeIn
            return act
        case let .decelerate(dist, dur):
            let act = SKAction.moveBy(x: 0, y: -dist, duration: dur)
            act.timingMode = .easeOut
            return act
        }
    }
}

// MARK: - VortexSpindle: animated reel column
class VortexSpindle: SKNode {

    private let viewport: CGSize                // visible area of the reel
    private let clipMask: SKCropNode            // hides symbols outside viewport
    private let symbolContainer: SKNode         // parent of all symbol sprites
    private var symbolSprites: [SKSpriteNode] = []
    private(set) var currentSpecimen: RuneSpecimen = .manna

    // Vertical spacing = 105% of reel height for smooth scroll
    private var symbolSpacing: CGFloat { viewport.height * 1.05 }

    // Symbol render size = 72% of shorter dimension
    private var symbolSize: CGSize {
        let side = min(viewport.width, viewport.height) * 0.72
        return CGSize(width: side, height: side)
    }

    init(size: CGSize) {
        self.viewport       = size
        self.clipMask       = SKCropNode()
        self.symbolContainer = SKNode()
        super.init()

        buildReelFrame()
        buildReelBackground()
        buildMaskContainer()
        buildPaylineIndicator()

        // Populate initial strip
        refreshStrip(targeting: .manna)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) not implemented") }

    // MARK: - Construction phases

    private func buildReelFrame() {
        let border = GeometryForge.panelNode(
            size: viewport,
            cutDepth: 10,
            fill: .clear,
            stroke: DesignToken.ceruleanVolt,
            strokeWidth: 2.5
        )
        border.glowWidth = 3
        addChild(border)
    }

    private func buildReelBackground() {
        let inset: CGFloat = 3
        let innerBounds = CGRect(
            x: -(viewport.width  / 2) + inset,
            y: -(viewport.height / 2) + inset,
            width:  viewport.width  - inset * 2,
            height: viewport.height - inset * 2
        )
        let bgPath = GeometryForge.chamferedOutline(bounds: innerBounds, cutDepth: 8)
        let bg = SKShapeNode(path: bgPath)
        bg.fillColor   = UIColor(red: 0.05, green: 0.02, blue: 0.14, alpha: 1)
        bg.strokeColor = .clear
        bg.zPosition   = -1
        addChild(bg)
    }

    private func buildMaskContainer() {
        let maskSprite    = SKSpriteNode(color: .white, size: viewport)
        clipMask.maskNode = maskSprite
        addChild(clipMask)
        clipMask.addChild(symbolContainer)
    }

    private func buildPaylineIndicator() {
        let lineSpan = viewport.width - 10
        let linePath = CGMutablePath()
        linePath.move(to:    CGPoint(x: -lineSpan / 2, y: 0))
        linePath.addLine(to: CGPoint(x:  lineSpan / 2, y: 0))
        let payline = SKShapeNode(path: linePath)
        payline.strokeColor = DesignToken.radiantCrimson.withAlphaComponent(0.30)
        payline.lineWidth   = 1
        payline.zPosition   = 4
        addChild(payline)
    }

    // MARK: - Symbol strip management

    // Build the ordered sequence of specimens and lay them out
    private func refreshStrip(targeting target: RuneSpecimen) {
        // Clear previous sprites
        symbolContainer.removeAllChildren()
        symbolSprites.removeAll()

        // Build pure symbol sequence (data only)
        let sequence = SymbolStrip.build(targeting: target, minLength: 8)

        // Map sequence to positioned sprites
        let sprites: [SKSpriteNode] = sequence.enumerated().map { index, specimen in
            let spriteName = SymbolStrip.assetName(for: specimen)
            let sprite     = SKSpriteNode(imageNamed: spriteName)
            sprite.size    = symbolSize
            // Lay out top-to-bottom; last item ends at y=0 after scrolling
            let yOffset    = CGFloat(sequence.count - 1 - index) * symbolSpacing
            sprite.position = CGPoint(x: 0, y: yOffset)
            return sprite
        }

        // Attach all sprites and record references
        sprites.forEach { symbolContainer.addChild($0) }
        symbolSprites = sprites

        // Reset container position: top of strip at screen top
        let totalHeight = CGFloat(sequence.count - 1) * symbolSpacing
        symbolContainer.position = CGPoint(x: 0, y: -totalHeight)
    }

    // MARK: - Spin animation

    func whirlTo(specimen: RuneSpecimen, delay: TimeInterval = 0, completion: @escaping () -> Void) {
        currentSpecimen = specimen

        // Rebuild strip so the target lands at bottom
        refreshStrip(targeting: specimen)

        let params       = SpinParameters.withDelay(delay)
        let totalSymbols = symbolSprites.count
        let totalTravel  = CGFloat(totalSymbols - 1) * symbolSpacing

        // Reset start position to the very top of the strip
        let startY = -totalTravel + symbolSpacing * CGFloat(totalSymbols - 1)
        symbolContainer.position = CGPoint(x: 0, y: startY)

        // Build two motion phases
        let fastDistance = totalTravel * params.fastFraction
        let slowDistance = totalTravel * (1 - params.fastFraction)

        let phases: [MotionPhase] = [
            .accelerate(distance: fastDistance, duration: params.accelerateFor),
            .decelerate(distance: slowDistance, duration: params.decelerateFor)
        ]

        // Assemble full action sequence: wait → fast → slow → callback
        var actions: [SKAction] = []
        if params.predelay > 0 {
            actions.append(SKAction.wait(forDuration: params.predelay))
        }
        actions.append(contentsOf: phases.map { $0.buildAction() })
        actions.append(SKAction.run { completion() })

        symbolContainer.run(SKAction.sequence(actions))
    }
}

// MARK: - Backward-compat alias
typealias ReelAxleNode = VortexSpindle

extension VortexSpindle {
    var currentGlyph: RuneSpecimen { currentSpecimen }
    func spinTo(glyph: RuneSpecimen, delay: TimeInterval = 0, completion: @escaping () -> Void) {
        whirlTo(specimen: glyph, delay: delay, completion: completion)
    }
}
