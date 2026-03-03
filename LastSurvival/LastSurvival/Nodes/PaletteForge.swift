// PaletteForge.swift — NEON VECTOR DYSTOPIA design system (refactored)

import SpriteKit
import UIKit

// MARK: - VisualRecipe: protocol describing a panel's appearance
protocol VisualRecipe {
    var surfaceTint: UIColor { get }
    var borderTint: UIColor { get }
    var edgeCut: CGFloat { get }
    var borderThickness: CGFloat { get }
}

// DefaultPanelRecipe — standard panel appearance using design tokens
struct DefaultPanelRecipe: VisualRecipe {
    var surfaceTint: UIColor    = DesignToken.vaultSurface
    var borderTint: UIColor     = DesignToken.radiantCrimson
    var edgeCut: CGFloat        = 10
    var borderThickness: CGFloat = 2
}

// MARK: - DesignToken: all color values for the neon theme
enum DesignToken {
    // Computed color properties — each resolves to exact RGBA
    static var cosmicInk: UIColor {
        UIColor(red: 0.03, green: 0.04, blue: 0.10, alpha: 1.0)
    }
    static var radiantCrimson: UIColor {
        UIColor(red: 1.00, green: 0.00, blue: 0.40, alpha: 1.0)
    }
    static var ceruleanVolt: UIColor {
        UIColor(red: 0.00, green: 0.80, blue: 1.00, alpha: 1.0)
    }
    static var phosphorLime: UIColor {
        UIColor(red: 0.78, green: 1.00, blue: 0.00, alpha: 1.0)
    }
    static var frostSheen: UIColor {
        UIColor(red: 0.94, green: 0.95, blue: 1.00, alpha: 1.0)
    }
    static var vermillionAlert: UIColor {
        UIColor(red: 1.00, green: 0.10, blue: 0.18, alpha: 1.0)
    }
    static var violetShadow: UIColor {
        UIColor(red: 0.28, green: 0.14, blue: 0.50, alpha: 1.0)
    }
    static var obsidianVeil: UIColor {
        UIColor(red: 0.10, green: 0.04, blue: 0.22, alpha: 1.0)
    }
    static var ashNebula: UIColor {
        UIColor(red: 0.50, green: 0.48, blue: 0.62, alpha: 1.0)
    }
    static var vaultSurface: UIColor {
        UIColor(red: 0.06, green: 0.04, blue: 0.16, alpha: 0.96)
    }
}

// MARK: - DisplayMetrics: adaptive scaling based on reference width 390pt
struct DisplayMetrics {
    let referenceWidth: CGFloat = 390.0
    let screenSize: CGSize

    init(screenSize: CGSize) {
        self.screenSize = screenSize
    }

    // Scale a base value proportionally to screen width
    func scaled(_ baseValue: CGFloat) -> CGFloat {
        baseValue * (screenSize.width / referenceWidth)
    }

    // The raw scale factor
    var factor: CGFloat {
        screenSize.width / referenceWidth
    }
}

// MARK: - TypographyScale: font vending with fallback chains
enum TypographyScale {
    // Condensed extra-bold for headers and titles
    static func headlineFont(at size: CGFloat) -> UIFont {
        let candidates: [(String, UIFont.Weight)] = [
            ("Futura-CondensedExtraBold", .black),
            ("Futura-Bold", .bold)
        ]
        for (name, _) in candidates {
            if let font = UIFont(name: name, size: size) { return font }
        }
        return UIFont.boldSystemFont(ofSize: size)
    }

    // Medium weight for body text and labels
    static func bodyFont(at size: CGFloat) -> UIFont {
        if let font = UIFont(name: "Futura-Medium", size: size) { return font }
        return UIFont.systemFont(ofSize: size)
    }

    // Semi-bold for accents and sub-labels
    static func accentFont(at size: CGFloat) -> UIFont {
        if let font = UIFont(name: "Futura-Bold", size: size) { return font }
        return UIFont.systemFont(ofSize: size, weight: .semibold)
    }

    // Produce an SKLabelNode configured with given parameters
    static func labelNode(
        text: String,
        size: CGFloat,
        tint: UIColor = DesignToken.frostSheen,
        weight: LabelWeight = .body
    ) -> SKLabelNode {
        let node = SKLabelNode()
        node.text = text
        switch weight {
        case .headline:
            node.fontName = "Futura-CondensedExtraBold"
        case .body:
            node.fontName = "Futura-Medium"
        case .accent:
            node.fontName = "Futura-Bold"
        }
        node.fontSize = size
        node.fontColor = tint
        node.verticalAlignmentMode = .center
        node.horizontalAlignmentMode = .center
        return node
    }

    enum LabelWeight { case headline, body, accent }
}

// MARK: - GeometryForge: constructing SpriteKit shapes
enum GeometryForge {

    // Compute an 8-sided chamfered path from a rect and cut depth
    static func chamferedOutline(bounds: CGRect, cutDepth: CGFloat) -> CGPath {
        let d = cutDepth
        let mutable = CGMutablePath()
        // Top edge: left-chamfer to right-chamfer
        mutable.move(to:    CGPoint(x: bounds.minX + d, y: bounds.maxY))
        mutable.addLine(to: CGPoint(x: bounds.maxX - d, y: bounds.maxY))
        // Top-right corner cut
        mutable.addLine(to: CGPoint(x: bounds.maxX,     y: bounds.maxY - d))
        // Right edge
        mutable.addLine(to: CGPoint(x: bounds.maxX,     y: bounds.minY + d))
        // Bottom-right corner cut
        mutable.addLine(to: CGPoint(x: bounds.maxX - d, y: bounds.minY))
        // Bottom edge
        mutable.addLine(to: CGPoint(x: bounds.minX + d, y: bounds.minY))
        // Bottom-left corner cut
        mutable.addLine(to: CGPoint(x: bounds.minX,     y: bounds.minY + d))
        // Left edge
        mutable.addLine(to: CGPoint(x: bounds.minX,     y: bounds.maxY - d))
        mutable.closeSubpath()
        return mutable
    }

    // Build a filled & stroked panel using a VisualRecipe
    static func panelNode(size: CGSize, recipe: VisualRecipe) -> SKShapeNode {
        let origin = CGPoint(x: -size.width / 2, y: -size.height / 2)
        let bounds = CGRect(origin: origin, size: size)
        let path   = chamferedOutline(bounds: bounds, cutDepth: recipe.edgeCut)
        let node   = SKShapeNode(path: path)
        node.fillColor   = recipe.surfaceTint
        node.strokeColor = recipe.borderTint
        node.lineWidth   = recipe.borderThickness
        return node
    }

    // Build a panel from explicit parameters (convenience overload)
    static func panelNode(
        size: CGSize,
        cutDepth: CGFloat = 10,
        fill: UIColor = DesignToken.vaultSurface,
        stroke: UIColor = DesignToken.radiantCrimson,
        strokeWidth: CGFloat = 2
    ) -> SKShapeNode {
        var recipe = DefaultPanelRecipe()
        recipe.surfaceTint     = fill
        recipe.borderTint      = stroke
        recipe.edgeCut         = cutDepth
        recipe.borderThickness = strokeWidth
        return panelNode(size: size, recipe: recipe)
    }

    // Legacy round-corner approximation: maps radius to cut depth
    static func roundedPanelNode(
        size: CGSize,
        radius: CGFloat = 16,
        fill: UIColor = DesignToken.vaultSurface,
        stroke: UIColor = DesignToken.radiantCrimson,
        strokeWidth: CGFloat = 2
    ) -> SKShapeNode {
        let depth = min(radius * 0.55, 14)
        return panelNode(size: size, cutDepth: depth, fill: fill, stroke: stroke, strokeWidth: strokeWidth)
    }

    // Place L-shaped corner bracket decorations on any SKNode
    static func attachCornerBrackets(
        to parent: SKNode,
        covering size: CGSize,
        armLength: CGFloat = 14,
        tint: UIColor = DesignToken.radiantCrimson,
        thickness: CGFloat = 2
    ) {
        // Encode each corner as (anchorX, anchorY, xDir, yDir)
        let halfW = size.width  / 2
        let halfH = size.height / 2
        let bracketDefs: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (-halfW,  halfH,  1, -1),   // top-left
            ( halfW,  halfH, -1, -1),   // top-right
            (-halfW, -halfH,  1,  1),   // bottom-left
            ( halfW, -halfH, -1,  1)    // bottom-right
        ]
        bracketDefs.forEach { (ax, ay, xd, yd) in
            let mpath = CGMutablePath()
            // Vertical arm of bracket
            mpath.move(to:    CGPoint(x: ax,              y: ay + yd * armLength))
            mpath.addLine(to: CGPoint(x: ax,              y: ay))
            // Horizontal arm of bracket
            mpath.addLine(to: CGPoint(x: ax + xd * armLength, y: ay))
            let bracketShape = SKShapeNode(path: mpath)
            bracketShape.strokeColor = tint
            bracketShape.lineWidth   = thickness
            bracketShape.fillColor   = .clear
            bracketShape.zPosition   = 2
            parent.addChild(bracketShape)
        }
    }

    // Thin horizontal divider line
    static func dividerLine(
        span: CGFloat,
        tint: UIColor = DesignToken.radiantCrimson,
        opacity: CGFloat = 0.45
    ) -> SKShapeNode {
        let linePath = CGMutablePath()
        linePath.move(to:    CGPoint(x: -span / 2, y: 0))
        linePath.addLine(to: CGPoint(x:  span / 2, y: 0))
        let shape = SKShapeNode(path: linePath)
        shape.strokeColor = tint.withAlphaComponent(opacity)
        shape.lineWidth   = 1
        return shape
    }
}

// MARK: - AnimationBlueprint: reusable SKAction factories
enum AnimationBlueprint {

    // Looping glow-pulse: glowWidth oscillates between 0 and peak
    static func glowOscillation(peakGlow: CGFloat = 5, halfPeriod: TimeInterval = 0.75) -> SKAction {
        let riseDuration  = halfPeriod
        let fallDuration  = halfPeriod
        let riseAction = SKAction.customAction(withDuration: riseDuration) { node, elapsed in
            guard let shape = node as? SKShapeNode else { return }
            let progress  = elapsed / CGFloat(riseDuration)
            shape.glowWidth = peakGlow * progress
        }
        let fallAction = SKAction.customAction(withDuration: fallDuration) { node, elapsed in
            guard let shape = node as? SKShapeNode else { return }
            let progress  = elapsed / CGFloat(fallDuration)
            shape.glowWidth = peakGlow * (1.0 - progress)
        }
        return SKAction.repeatForever(SKAction.sequence([riseAction, fallAction]))
    }

    // Quick scale-down press feedback
    static func pressDown(scale: CGFloat = 0.92, duration: TimeInterval = 0.07) -> SKAction {
        SKAction.scale(to: scale, duration: duration)
    }

    // Scale back to normal
    static func releaseUp(duration: TimeInterval = 0.10) -> SKAction {
        SKAction.scale(to: 1.0, duration: duration)
    }

    // Fade + scale entrance for modal panels
    static func modalEntrance(targetScale: CGFloat = 1.0, duration: TimeInterval = 0.22) -> SKAction {
        SKAction.group([
            SKAction.scale(to: targetScale, duration: duration),
            SKAction.fadeIn(withDuration: duration)
        ])
    }

    // Fade + scale exit for modal panels
    static func modalExit(targetScale: CGFloat = 0.65, duration: TimeInterval = 0.18) -> SKAction {
        SKAction.group([
            SKAction.scale(to: targetScale, duration: duration),
            SKAction.fadeOut(withDuration: duration)
        ])
    }

    // Staggered alpha-in for a list of nodes
    static func cascade(nodes: [SKNode], baseDelay: TimeInterval, perStep: TimeInterval) {
        nodes.enumerated().forEach { index, node in
            node.alpha = 0
            let delay  = baseDelay + Double(index) * perStep
            node.run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.fadeIn(withDuration: 0.25)
            ]))
        }
    }
}

// MARK: - ChromaticAnvil: main namespace alias used throughout the project
// Internally delegates to DesignToken, TypographyScale, GeometryForge, AnimationBlueprint
enum ChromaticAnvil {

    // MARK: Colors — forward to DesignToken
    static var stygianDepth:  UIColor { DesignToken.cosmicInk        }
    static var fluxCrimson:   UIColor { DesignToken.radiantCrimson   }
    static var caerulanSurge: UIColor { DesignToken.ceruleanVolt     }
    static var viridianFlare: UIColor { DesignToken.phosphorLime     }
    static var pallorLux:     UIColor { DesignToken.frostSheen       }
    static var sanguineFlare: UIColor { DesignToken.vermillionAlert  }
    static var umbraPigment:  UIColor { DesignToken.violetShadow     }
    static var tenebrisPall:  UIColor { DesignToken.obsidianVeil     }
    static var scoriaDust:    UIColor { DesignToken.ashNebula        }
    static var crypticVoid:   UIColor { DesignToken.vaultSurface     }

    // MARK: Fonts — forward to TypographyScale
    static func runestoneFont(size: CGFloat) -> UIFont  { TypographyScale.headlineFont(at: size) }
    static func vellumFont(size: CGFloat) -> UIFont     { TypographyScale.bodyFont(at: size)     }
    static func cartoucheFont(size: CGFloat) -> UIFont  { TypographyScale.accentFont(at: size)   }

    // MARK: Label — forward to TypographyScale
    static func fashionGlyph(
        text: String,
        fontSize: CGFloat,
        color: UIColor = DesignToken.frostSheen,
        bold: Bool = false
    ) -> SKLabelNode {
        TypographyScale.labelNode(
            text: text,
            size: fontSize,
            tint: color,
            weight: bold ? .headline : .body
        )
    }

    // MARK: Shapes — forward to GeometryForge
    static func bevelPath(rect: CGRect, incision: CGFloat) -> CGPath {
        GeometryForge.chamferedOutline(bounds: rect, cutDepth: incision)
    }

    static func smeltFacet(
        size: CGSize,
        chamfer: CGFloat = 10,
        fillColor: UIColor = DesignToken.vaultSurface,
        strokeColor: UIColor = DesignToken.radiantCrimson,
        lineWidth: CGFloat = 2
    ) -> SKShapeNode {
        GeometryForge.panelNode(
            size: size, cutDepth: chamfer,
            fill: fillColor, stroke: strokeColor, strokeWidth: lineWidth
        )
    }

    static func smeltMedallion(
        size: CGSize,
        cornerRadius: CGFloat = 16,
        fillColor: UIColor = DesignToken.vaultSurface,
        strokeColor: UIColor = DesignToken.radiantCrimson,
        lineWidth: CGFloat = 2
    ) -> SKShapeNode {
        GeometryForge.roundedPanelNode(
            size: size, radius: cornerRadius,
            fill: fillColor, stroke: strokeColor, strokeWidth: lineWidth
        )
    }

    static func inscribeCornerRunes(
        to node: SKNode,
        size: CGSize,
        runeLen: CGFloat = 14,
        color: UIColor = DesignToken.radiantCrimson,
        lineWidth: CGFloat = 2
    ) {
        GeometryForge.attachCornerBrackets(
            to: node, covering: size,
            armLength: runeLen, tint: color, thickness: lineWidth
        )
    }

    static func smeltCesura(
        width: CGFloat,
        color: UIColor = DesignToken.radiantCrimson,
        alpha: CGFloat = 0.45
    ) -> SKShapeNode {
        GeometryForge.dividerLine(span: width, tint: color, opacity: alpha)
    }

    // MARK: Animations — forward to AnimationBlueprint
    static func radiantPulse(from _: UIColor, to _: UIColor) -> SKAction {
        AnimationBlueprint.glowOscillation()
    }
}

// MARK: - CGSize: adaptive scale extension
extension CGSize {
    // Primary scale factor relative to 390-pt reference width
    var calibration: CGFloat {
        let metrics = DisplayMetrics(screenSize: self)
        return metrics.factor
    }
    // Backward-compatible alias
    var adaptiveScale: CGFloat { calibration }
}

// MARK: - PaletteForge: typealias + legacy bridge extensions
typealias PaletteForge = ChromaticAnvil

extension ChromaticAnvil {

    // MARK: Color aliases matching old property names
    static var voidBlack:  UIColor { stygianDepth  }
    static var neonPink:   UIColor { fluxCrimson   }
    static var plasmaBlue: UIColor { caerulanSurge }
    static var acidLime:   UIColor { viridianFlare }
    static var snowWhite:  UIColor { pallorLux     }
    static var alertRed:   UIColor { sanguineFlare }
    static var midPurple:  UIColor { umbraPigment  }
    static var deepViolet: UIColor { tenebrisPall  }
    static var dimGray:    UIColor { scoriaDust    }
    static var panelBg:    UIColor { crypticVoid   }

    // MARK: Method aliases for call-site compatibility
    static func makeLabel(
        text: String,
        fontSize: CGFloat,
        color: UIColor = DesignToken.frostSheen,
        bold: Bool = false
    ) -> SKLabelNode {
        fashionGlyph(text: text, fontSize: fontSize, color: color, bold: bold)
    }

    static func makeChamferedPanel(
        size: CGSize,
        chamfer: CGFloat = 10,
        fillColor: UIColor = DesignToken.vaultSurface,
        strokeColor: UIColor = DesignToken.radiantCrimson,
        lineWidth: CGFloat = 2
    ) -> SKShapeNode {
        smeltFacet(size: size, chamfer: chamfer,
                   fillColor: fillColor, strokeColor: strokeColor, lineWidth: lineWidth)
    }

    static func makeRoundedPanel(
        size: CGSize,
        cornerRadius: CGFloat = 16,
        fillColor: UIColor = DesignToken.vaultSurface,
        strokeColor: UIColor = DesignToken.radiantCrimson,
        lineWidth: CGFloat = 2
    ) -> SKShapeNode {
        smeltMedallion(size: size, cornerRadius: cornerRadius,
                       fillColor: fillColor, strokeColor: strokeColor, lineWidth: lineWidth)
    }

    static func chamferedPath(rect: CGRect, chamfer: CGFloat) -> CGPath {
        bevelPath(rect: rect, incision: chamfer)
    }

    static func addCornerBrackets(
        to node: SKNode,
        size: CGSize,
        bracketLen: CGFloat = 14,
        color: UIColor = DesignToken.radiantCrimson,
        lineWidth: CGFloat = 2
    ) {
        inscribeCornerRunes(to: node, size: size,
                            runeLen: bracketLen, color: color, lineWidth: lineWidth)
    }

    static func glowPulse(from: UIColor, to: UIColor) -> SKAction {
        radiantPulse(from: from, to: to)
    }

    static func makeDivider(
        width: CGFloat,
        color: UIColor = DesignToken.radiantCrimson,
        alpha: CGFloat = 0.45
    ) -> SKShapeNode {
        smeltCesura(width: width, color: color, alpha: alpha)
    }
}
