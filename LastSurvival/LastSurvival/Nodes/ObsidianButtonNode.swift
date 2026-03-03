// ObsidianButtonNode.swift — ClaviculaNodelet: neon chamfered button (refactored)

import SpriteKit

// MARK: - ButtonAppearance: declarative style configuration for a button
struct ButtonAppearance {
    var bodySize: CGSize
    var labelText: String
    var primaryColor: UIColor
    var labelColor: UIColor
    var cutDepth: CGFloat

    init(
        size: CGSize,
        title: String,
        fill: UIColor = DesignToken.radiantCrimson,
        textColor: UIColor = DesignToken.frostSheen,
        chamfer: CGFloat = 10
    ) {
        self.bodySize     = size
        self.labelText    = title
        self.primaryColor = fill
        self.labelColor   = textColor
        self.cutDepth     = chamfer
    }
}

// MARK: - ButtonInteractionState: drives animation and hit-testing
enum ButtonInteractionState {
    case idle
    case pressed
    case disabled

    var alphaValue: CGFloat {
        switch self {
        case .idle:     return 1.0
        case .pressed:  return 1.0
        case .disabled: return 0.35
        }
    }

    var glowValue: CGFloat {
        switch self {
        case .idle:     return 2.5
        case .pressed:  return 0.0
        case .disabled: return 0.0
        }
    }
}

// MARK: - ClaviculaNodelet: chamfered arcade button driven by state machine
class ClaviculaNodelet: SKNode {

    // Public interaction callback
    var onImpact: (() -> Void)?

    // Internal components
    private let bodyShape: SKShapeNode
    private let titleLabel: SKLabelNode
    private let appearance: ButtonAppearance

    // State machine
    private var interactionState: ButtonInteractionState = .idle {
        didSet { applyState(interactionState, animated: true) }
    }

    init(
        size: CGSize,
        title: String,
        fillColor: UIColor = ChromaticAnvil.fluxCrimson,
        titleColor: UIColor = ChromaticAnvil.pallorLux,
        cornerRadius: CGFloat = 10
    ) {
        // Map legacy cornerRadius parameter to actual cut depth
        let resolvedChamfer = min(size.height * 0.32, cornerRadius * 0.7)

        let config = ButtonAppearance(
            size: size,
            title: title,
            fill: fillColor,
            textColor: titleColor,
            chamfer: resolvedChamfer
        )
        self.appearance = config

        // Build body shape using GeometryForge
        let bounds = CGRect(
            x: -config.bodySize.width  / 2,
            y: -config.bodySize.height / 2,
            width:  config.bodySize.width,
            height: config.bodySize.height
        )
        let bodyPath  = GeometryForge.chamferedOutline(bounds: bounds, cutDepth: config.cutDepth)
        bodyShape = SKShapeNode(path: bodyPath)
        bodyShape.fillColor   = config.primaryColor
        bodyShape.strokeColor = config.primaryColor.withAlphaComponent(0.85)
        bodyShape.lineWidth   = 2
        bodyShape.glowWidth   = ButtonInteractionState.idle.glowValue

        // Build label using TypographyScale
        titleLabel = TypographyScale.labelNode(
            text: config.labelText,
            size: config.bodySize.height * 0.40,
            tint: config.labelColor,
            weight: .headline
        )
        titleLabel.zPosition = 1

        super.init()
        isUserInteractionEnabled = true

        // Assemble hierarchy: button body contains label
        addChild(bodyShape)
        bodyShape.addChild(titleLabel)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) not implemented") }

    // MARK: - State-driven visual transitions
    private func applyState(_ state: ButtonInteractionState, animated: Bool) {
        let targetAlpha = state.alphaValue
        let targetGlow  = state.glowValue

        if animated {
            bodyShape.run(SKAction.customAction(withDuration: 0.07) { [weak self] _, _ in
                guard let self else { return }
                self.bodyShape.alpha     = targetAlpha
                self.bodyShape.glowWidth = targetGlow
            })
        } else {
            bodyShape.alpha     = targetAlpha
            bodyShape.glowWidth = targetGlow
        }
    }

    // Animate: shrink + highlight fill on press
    private func animatePress() {
        let shrink = SKAction.scale(to: 0.92, duration: 0.07)
        let tint   = SKAction.customAction(withDuration: 0.07) { node, _ in
            (node as? SKShapeNode)?.fillColor = DesignToken.frostSheen.withAlphaComponent(0.25)
        }
        bodyShape.run(SKAction.group([shrink, tint]))
    }

    // Animate: restore fill + scale up on release, then fire callback
    private func animateRelease(thenFire callback: (() -> Void)?) {
        let originalFill = appearance.primaryColor
        let restoreFill = SKAction.customAction(withDuration: 0.0) { node, _ in
            (node as? SKShapeNode)?.fillColor = originalFill
        }
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.10)
        bodyShape.run(SKAction.sequence([restoreFill, scaleUp])) {
            callback?()
        }
    }

    // Animate: restore fill + scale up on cancel (no callback)
    private func animateCancel() {
        bodyShape.fillColor = appearance.primaryColor
        bodyShape.run(SKAction.scale(to: 1.0, duration: 0.08))
    }

    // MARK: - Touch handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard interactionState != .disabled else { return }
        interactionState = .pressed
        animatePress()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard interactionState == .pressed else { return }
        interactionState = .idle
        animateRelease(thenFire: onImpact)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard interactionState == .pressed else { return }
        interactionState = .idle
        animateCancel()
    }

    // MARK: - Public API
    func inscribeLabel(_ text: String) {
        titleLabel.text = text
    }

    func toggleReceptive(_ enabled: Bool) {
        let nextState: ButtonInteractionState = enabled ? .idle : .disabled
        isUserInteractionEnabled = enabled
        interactionState = nextState
    }
}

// MARK: - Backward-compat aliases
typealias ObsidianButtonNode = ClaviculaNodelet

extension ClaviculaNodelet {
    var onTap: (() -> Void)? {
        get { onImpact }
        set { onImpact = newValue }
    }
    func setTitle(_ text: String) { inscribeLabel(text) }
    func setEnabled(_ enabled: Bool) { toggleReceptive(enabled) }
}
