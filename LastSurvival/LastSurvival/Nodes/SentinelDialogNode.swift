// SentinelDialogNode.swift — Custom modal dialog (replaces system alerts)

import SpriteKit

class SentinelDialogNode: SKNode {

    private let backdrop: SKShapeNode
    private let panel: SKShapeNode
    private let titleLbl: SKLabelNode
    private let bodyLbl: SKLabelNode
    private var confirmBtn: ObsidianButtonNode?
    private var cancelBtn: ObsidianButtonNode?

    var onConfirm: (() -> Void)?
    var onCancel: (() -> Void)?

    init(sceneSize: CGSize, title: String, body: String, confirmText: String, cancelText: String? = nil) {
        let sc = sceneSize.adaptiveScale

        // Dim backdrop
        backdrop = SKShapeNode(rectOf: sceneSize)
        backdrop.fillColor = UIColor.black.withAlphaComponent(0.65)
        backdrop.strokeColor = .clear
        backdrop.zPosition = 0

        // Panel
        let panelW = min(sceneSize.width * 0.82, 340 * sc)
        let panelH: CGFloat = cancelText != nil ? 240 * sc : 200 * sc
        panel = PaletteForge.makeRoundedPanel(
            size: CGSize(width: panelW, height: panelH),
            cornerRadius: 20 * sc,
            fillColor: UIColor(red: 0.08, green: 0.09, blue: 0.13, alpha: 0.98),
            strokeColor: PaletteForge.cinderGold,
            lineWidth: 2
        )
        panel.zPosition = 1

        // Title
        titleLbl = PaletteForge.makeLabel(text: title, fontSize: 20 * sc, color: PaletteForge.cinderGold, bold: true)
        titleLbl.position = CGPoint(x: 0, y: panelH * 0.28)
        titleLbl.zPosition = 2

        // Body
        bodyLbl = SKLabelNode()
        bodyLbl.text = body
        bodyLbl.fontName = "AvenirNext-Medium"
        bodyLbl.fontSize = 14 * sc
        bodyLbl.fontColor = PaletteForge.ashWhite
        bodyLbl.verticalAlignmentMode = .center
        bodyLbl.horizontalAlignmentMode = .center
        bodyLbl.numberOfLines = 0
        bodyLbl.preferredMaxLayoutWidth = panelW - 40 * sc
        bodyLbl.position = CGPoint(x: 0, y: 0)
        bodyLbl.zPosition = 2

        super.init()

        addChild(backdrop)
        addChild(panel)
        panel.addChild(titleLbl)
        panel.addChild(bodyLbl)

        // Confirm button
        let btnW = cancelText != nil ? panelW * 0.44 : panelW * 0.6
        let btnH = 44 * sc
        let btnY = -(panelH * 0.32)

        let cBtn = ObsidianButtonNode(
            size: CGSize(width: btnW, height: btnH),
            title: confirmText,
            fillColor: PaletteForge.cinderGold,
            titleColor: PaletteForge.obsidian
        )
        cBtn.position = CGPoint(x: cancelText != nil ? panelW * 0.24 : 0, y: btnY)
        cBtn.zPosition = 2
        cBtn.onTap = { [weak self] in self?.onConfirm?() }
        panel.addChild(cBtn)
        confirmBtn = cBtn

        // Cancel button
        if let cancelText = cancelText {
            let xBtn = ObsidianButtonNode(
                size: CGSize(width: btnW, height: btnH),
                title: cancelText,
                fillColor: PaletteForge.slateGray,
                titleColor: PaletteForge.ashWhite
            )
            xBtn.position = CGPoint(x: -panelW * 0.24, y: btnY)
            xBtn.zPosition = 2
            xBtn.onTap = { [weak self] in self?.onCancel?() }
            panel.addChild(xBtn)
            cancelBtn = xBtn
        }

        // Entrance animation
        panel.setScale(0.7)
        panel.alpha = 0
        let appear = SKAction.group([
            SKAction.scale(to: 1.0, duration: 0.25),
            SKAction.fadeIn(withDuration: 0.25)
        ])
        panel.run(appear)
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    func dismiss(completion: (() -> Void)? = nil) {
        let vanish = SKAction.group([
            SKAction.scale(to: 0.7, duration: 0.18),
            SKAction.fadeOut(withDuration: 0.18)
        ])
        panel.run(vanish) { [weak self] in
            self?.removeFromParent()
            completion?()
        }
        backdrop.run(SKAction.fadeOut(withDuration: 0.18))
    }
}
