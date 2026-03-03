// ObsidianButtonNode.swift — Reusable styled button node

import SpriteKit

class ObsidianButtonNode: SKNode {

    var onTap: (() -> Void)?
    private let shape: SKShapeNode
    private let label: SKLabelNode

    init(size: CGSize, title: String, fillColor: UIColor = PaletteForge.cinderGold, titleColor: UIColor = PaletteForge.obsidian, cornerRadius: CGFloat = 10) {
        let path = UIBezierPath(roundedRect: CGRect(x: -size.width/2, y: -size.height/2, width: size.width, height: size.height), cornerRadius: cornerRadius)
        shape = SKShapeNode(path: path.cgPath)
        shape.fillColor = fillColor
        shape.strokeColor = fillColor.withAlphaComponent(0.6)
        shape.lineWidth = 1

        label = SKLabelNode()
        label.text = title
        label.fontName = "AvenirNext-Heavy"
        label.fontSize = size.height * 0.38
        label.fontColor = titleColor
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.zPosition = 1

        super.init()
        isUserInteractionEnabled = true
        addChild(shape)
        shape.addChild(label)
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        shape.run(SKAction.scale(to: 0.93, duration: 0.08))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        shape.run(SKAction.scale(to: 1.0, duration: 0.08)) { [weak self] in
            self?.onTap?()
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        shape.run(SKAction.scale(to: 1.0, duration: 0.08))
    }

    func setTitle(_ text: String) { label.text = text }
    func setEnabled(_ enabled: Bool) {
        isUserInteractionEnabled = enabled
        shape.alpha = enabled ? 1.0 : 0.4
    }
}
