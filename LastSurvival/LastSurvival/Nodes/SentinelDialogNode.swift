// SentinelDialogNode.swift — MantletParley: custom modal dialog (refactored)

import SpriteKit

// MARK: - DialogConfiguration: declarative description of a dialog
struct DialogConfiguration {
    var heading: String
    var message: String
    var primaryAction: ActionDescriptor
    var secondaryAction: ActionDescriptor?

    struct ActionDescriptor {
        var label: String
        var accentColor: UIColor
        var handler: (() -> Void)?

        init(label: String, accentColor: UIColor, handler: (() -> Void)? = nil) {
            self.label       = label
            self.accentColor = accentColor
            self.handler     = handler
        }
    }
}

// MARK: - ModalOverlay protocol: common overlay lifecycle
protocol ModalOverlay: AnyObject {
    func dismiss(completion: (() -> Void)?)
}

// MARK: - MantletParley: modal overlay built from DialogConfiguration
class MantletParley: SKNode, ModalOverlay {

    // Callbacks wired through configuration
    var onRatify: (() -> Void)?
    var onRevoke: (() -> Void)?

    // Internal references
    private let curtain: SKShapeNode
    private let container: SKShapeNode
    private let scaleRef: CGFloat

    // Computed dimensions stored for layout helpers
    private let panelWidth:  CGFloat
    private let panelHeight: CGFloat

    init(
        sceneSize: CGSize,
        title: String,
        body: String,
        confirmText: String,
        cancelText: String? = nil
    ) {
        let sc = sceneSize.calibration
        self.scaleRef = sc

        // Build configuration from legacy parameters
        var config = DialogConfiguration(
            heading: title,
            message: body,
            primaryAction: .init(
                label: confirmText,
                accentColor: DesignToken.radiantCrimson
            )
        )
        if let ct = cancelText {
            config.secondaryAction = .init(label: ct, accentColor: DesignToken.violetShadow)
        }

        // Compute panel dimensions
        let w = min(sceneSize.width * 0.82, 340 * sc)
        let h: CGFloat = config.secondaryAction != nil ? 240 * sc : 200 * sc
        self.panelWidth  = w
        self.panelHeight = h

        // Backdrop: full-screen dim
        curtain = SKShapeNode(rectOf: sceneSize)
        curtain.fillColor   = UIColor(red: 0, green: 0, blue: 0.05, alpha: 0.72)
        curtain.strokeColor = .clear
        curtain.zPosition   = 0

        // Container panel: chamfered, deep violet fill
        let containerFill = UIColor(red: 0.06, green: 0.04, blue: 0.18, alpha: 0.98)
        container = GeometryForge.panelNode(
            size: CGSize(width: w, height: h),
            cutDepth: 12,
            fill: containerFill,
            stroke: DesignToken.radiantCrimson,
            strokeWidth: 2.5
        )
        container.glowWidth = 2
        container.zPosition = 1

        super.init()

        // Assemble structure in four distinct phases
        mountBackdrop()
        mountContainer()
        mountContent(config: config, panelW: w, panelH: h, sc: sc)
        mountActions(config: config, panelW: w, panelH: h, sc: sc)

        // Entrance animation: scale-in from 65%
        container.setScale(0.65)
        container.alpha = 0
        container.run(AnimationBlueprint.modalEntrance())
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) not implemented") }

    // MARK: - Four-phase assembly

    private func mountBackdrop() {
        addChild(curtain)
    }

    private func mountContainer() {
        addChild(container)
    }

    private func mountContent(config: DialogConfiguration, panelW: CGFloat, panelH: CGFloat, sc: CGFloat) {
        // Heading label
        let headingNode = TypographyScale.labelNode(
            text: config.heading,
            size: 20 * sc,
            tint: DesignToken.radiantCrimson,
            weight: .headline
        )
        headingNode.position  = CGPoint(x: 0, y: panelH * 0.28)
        headingNode.zPosition = 2
        container.addChild(headingNode)

        // Decorative divider below heading
        let divider = GeometryForge.dividerLine(
            span: panelW * 0.72,
            tint: DesignToken.radiantCrimson,
            opacity: 0.35
        )
        divider.position  = CGPoint(x: 0, y: panelH * 0.12)
        divider.zPosition = 2
        container.addChild(divider)

        // Body message label (multi-line)
        let bodyNode = SKLabelNode()
        bodyNode.text                  = config.message
        bodyNode.fontName              = "Futura-Medium"
        bodyNode.fontSize              = 14 * sc
        bodyNode.fontColor             = DesignToken.frostSheen
        bodyNode.verticalAlignmentMode   = .center
        bodyNode.horizontalAlignmentMode = .center
        bodyNode.numberOfLines           = 0
        bodyNode.preferredMaxLayoutWidth = panelW - 40 * sc
        bodyNode.position  = .zero
        bodyNode.zPosition = 2
        container.addChild(bodyNode)
    }

    private func mountActions(config: DialogConfiguration, panelW: CGFloat, panelH: CGFloat, sc: CGFloat) {
        let hasSecondary = config.secondaryAction != nil
        let buttonW = hasSecondary ? panelW * 0.44 : panelW * 0.60
        let buttonH: CGFloat = 44 * sc
        let buttonRowY: CGFloat = -(panelH * 0.32)

        // Primary (confirm) button
        let primaryXOffset: CGFloat = hasSecondary ? panelW * 0.24 : 0
        let primaryBtn = ClaviculaNodelet(
            size: CGSize(width: buttonW, height: buttonH),
            title: config.primaryAction.label,
            fillColor: config.primaryAction.accentColor,
            titleColor: DesignToken.frostSheen
        )
        primaryBtn.position  = CGPoint(x: primaryXOffset, y: buttonRowY)
        primaryBtn.zPosition = 2
        primaryBtn.onImpact  = { [weak self] in self?.onRatify?() }
        container.addChild(primaryBtn)

        // Secondary (cancel) button — only if provided
        guard let secondaryAction = config.secondaryAction else { return }
        let secondaryBtn = ClaviculaNodelet(
            size: CGSize(width: buttonW, height: buttonH),
            title: secondaryAction.label,
            fillColor: secondaryAction.accentColor,
            titleColor: DesignToken.frostSheen
        )
        secondaryBtn.position  = CGPoint(x: -panelW * 0.24, y: buttonRowY)
        secondaryBtn.zPosition = 2
        secondaryBtn.onImpact  = { [weak self] in self?.onRevoke?() }
        container.addChild(secondaryBtn)
    }

    // MARK: - ModalOverlay conformance
    func dismiss(completion: (() -> Void)? = nil) {
        dissolve(completion: completion)
    }

    func dissolve(completion: (() -> Void)? = nil) {
        // Panel exit animation
        container.run(AnimationBlueprint.modalExit()) { [weak self] in
            self?.removeFromParent()
            completion?()
        }
        // Fade curtain simultaneously
        curtain.run(SKAction.fadeOut(withDuration: 0.18))
    }
}

// MARK: - Backward-compat alias
typealias SentinelDialogNode = MantletParley

extension MantletParley {
    var onConfirm: (() -> Void)? {
        get { onRatify }
        set { onRatify = newValue }
    }
    var onCancel: (() -> Void)? {
        get { onRevoke }
        set { onRevoke = newValue }
    }
}
