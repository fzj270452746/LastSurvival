// PaletteForge.swift — Shared colors, fonts, and UI helpers

import SpriteKit
import UIKit

enum PaletteForge {
    // MARK: - Colors
    static let obsidian    = UIColor(red: 0.05, green: 0.05, blue: 0.08, alpha: 1)
    static let cinderGold  = UIColor(red: 0.95, green: 0.78, blue: 0.20, alpha: 1)
    static let ashWhite    = UIColor(red: 0.92, green: 0.90, blue: 0.85, alpha: 1)
    static let bloodRed    = UIColor(red: 0.80, green: 0.10, blue: 0.10, alpha: 1)
    static let jadeTeal    = UIColor(red: 0.10, green: 0.75, blue: 0.55, alpha: 1)
    static let slateGray   = UIColor(red: 0.25, green: 0.27, blue: 0.32, alpha: 1)
    static let emberOrange = UIColor(red: 0.95, green: 0.45, blue: 0.10, alpha: 1)
    static let deepPurple  = UIColor(red: 0.28, green: 0.10, blue: 0.45, alpha: 1)
    static let panelBg     = UIColor(red: 0.10, green: 0.11, blue: 0.15, alpha: 0.92)

    // MARK: - Fonts
    static func glyphFont(size: CGFloat) -> UIFont {
        UIFont(name: "AvenirNext-Heavy", size: size) ?? UIFont.boldSystemFont(ofSize: size)
    }
    static func bodyFont(size: CGFloat) -> UIFont {
        UIFont(name: "AvenirNext-Medium", size: size) ?? UIFont.systemFont(ofSize: size)
    }
    static func labelFont(size: CGFloat) -> UIFont {
        UIFont(name: "AvenirNext-DemiBold", size: size) ?? UIFont.systemFont(ofSize: size, weight: .semibold)
    }

    // MARK: - Helpers
    static func makeLabel(text: String, fontSize: CGFloat, color: UIColor = ashWhite, bold: Bool = false) -> SKLabelNode {
        let lbl = SKLabelNode()
        lbl.text = text
        lbl.fontName = bold ? "AvenirNext-Heavy" : "AvenirNext-Medium"
        lbl.fontSize = fontSize
        lbl.fontColor = color
        lbl.verticalAlignmentMode = .center
        lbl.horizontalAlignmentMode = .center
        return lbl
    }

    static func makeRoundedPanel(size: CGSize, cornerRadius: CGFloat = 16, fillColor: UIColor = panelBg, strokeColor: UIColor = cinderGold, lineWidth: CGFloat = 1.5) -> SKShapeNode {
        let path = UIBezierPath(roundedRect: CGRect(origin: CGPoint(x: -size.width/2, y: -size.height/2), size: size), cornerRadius: cornerRadius)
        let node = SKShapeNode(path: path.cgPath)
        node.fillColor = fillColor
        node.strokeColor = strokeColor
        node.lineWidth = lineWidth
        return node
    }

    // Glowing border pulse action
    static func glowPulse(from: UIColor, to: UIColor) -> SKAction {
        let fadeOut = SKAction.customAction(withDuration: 0.8) { node, t in
            guard let shape = node as? SKShapeNode else { return }
            let progress = t / 0.8
            shape.glowWidth = 4 * (1 - progress)
        }
        let fadeIn = SKAction.customAction(withDuration: 0.8) { node, t in
            guard let shape = node as? SKShapeNode else { return }
            let progress = t / 0.8
            shape.glowWidth = 4 * progress
        }
        return SKAction.repeatForever(SKAction.sequence([fadeIn, fadeOut]))
    }
}

// MARK: - Scale helper for adaptive layout
extension CGSize {
    /// Scale factor relative to iPhone 14 base width (390pt)
    var adaptiveScale: CGFloat { width / 390.0 }
}
