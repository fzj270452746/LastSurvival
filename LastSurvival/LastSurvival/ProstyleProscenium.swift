// ProstyleProscenium.swift — Template Method abstract base scene
// Pattern: Template Method
// New types: ProstyleProscenium (abstract base), shared scaffold helpers

import SpriteKit

// MARK: - ProsceniumHeaderConfig: declarative header description
struct ProsceniumHeaderConfig {
    var titleText:   String
    var titleTint:   UIColor
    var barHeight:   CGFloat
    var barFill:     UIColor
    var showBackBtn: Bool
    var backLabel:   String
    var backAction:  (() -> Void)?

    static func standard(
        title: String,
        tint: UIColor = DesignToken.ceruleanVolt,
        back: (() -> Void)? = nil
    ) -> ProsceniumHeaderConfig {
        ProsceniumHeaderConfig(
            titleText:   title,
            titleTint:   tint,
            barHeight:   46,
            barFill:     UIColor(red: 0.06, green: 0.03, blue: 0.18, alpha: 0.92),
            showBackBtn: back != nil,
            backLabel:   "BACK",
            backAction:  back
        )
    }
}

// MARK: - ProstyleProscenium: abstract base scene with shared scaffold logic
// Subclasses override buildContent() to supply scene-specific nodes.
// The template method didMove(to:) orchestrates four scaffold phases in order:
//   1. buildSubstrate()  — background (wallpaper + dim overlay)
//   2. buildCornice()    — optional top header bar
//   3. buildContent()    — scene-specific content (MUST override)
//   4. buildRetour()     — optional bottom navigation or footer
class ProstyleProscenium: SKScene {

    // Subclasses may override these to customise scaffold behaviour
    var substrateBgAlpha:  CGFloat      = 0.12
    var substrateDimAlpha: CGFloat      = 0.65
    var headerConfig:      ProsceniumHeaderConfig?   // nil = no header

    // Cached safe-area metrics set once in didMove
    private(set) var safeTopInset:    CGFloat = 44
    private(set) var safeBottomInset: CGFloat = 34

    // The Y of the header's bottom edge — useful for subclasses laying out content
    private(set) var headerBottomY: CGFloat = 0

    // Scale factor — cached after didMove
    private(set) var displayScale: CGFloat = 1

    // MARK: - Template Entry Point
    override func didMove(to view: SKView) {
        safeTopInset    = view.safeAreaInsets.top    > 0 ? view.safeAreaInsets.top    : 44
        safeBottomInset = view.safeAreaInsets.bottom > 0 ? view.safeAreaInsets.bottom : 34
        displayScale    = size.calibration

        backgroundColor = DesignToken.cosmicInk

        buildSubstrate()
        buildCornice()
        buildContent()
        buildRetour()
    }

    // MARK: - Phase 1: substrate (background layers) — final, subclass customises via properties
    final func buildSubstrate() {
        mountScaffoldBackground(
            bgAlpha:  substrateBgAlpha,
            dimAlpha: substrateDimAlpha
        )
    }

    // MARK: - Phase 2: cornice (header bar) — subclass sets headerConfig before super.didMove
    func buildCornice() {
        guard let cfg = headerConfig else { return }
        headerBottomY = mountScaffoldHeader(config: cfg, safeTop: safeTopInset)
    }

    // MARK: - Phase 3: content — MUST override in subclass
    func buildContent() {
        // Default: no-op. Override in every concrete subclass.
    }

    // MARK: - Phase 4: retour (footer / back overlay) — override if needed
    func buildRetour() {
        // Default: no-op. Override when scene needs a persistent footer.
    }

    // MARK: - Shared Scaffold Helpers

    /// Mount standard background: semi-transparent wallpaper + colour dim overlay
    func mountScaffoldBackground(bgAlpha: CGFloat = 0.12, dimAlpha: CGFloat = 0.65) {
        let wallpaper       = SKSpriteNode(imageNamed: "bg_main")
        wallpaper.size      = size
        wallpaper.position  = CGPoint(x: size.width / 2, y: size.height / 2)
        wallpaper.alpha     = bgAlpha
        wallpaper.zPosition = -1
        addChild(wallpaper)

        let dimLayer         = SKShapeNode(rectOf: size)
        dimLayer.position    = CGPoint(x: size.width / 2, y: size.height / 2)
        dimLayer.fillColor   = UIColor(red: 0.03, green: 0.02, blue: 0.14, alpha: dimAlpha)
        dimLayer.strokeColor = .clear
        dimLayer.zPosition   = 0
        addChild(dimLayer)
    }

    /// Mount a standard header bar.
    /// Returns the Y of the bar's bottom edge for content layout.
    @discardableResult
    func mountScaffoldHeader(config: ProsceniumHeaderConfig, safeTop: CGFloat) -> CGFloat {
        let sc         = displayScale
        let barH       = config.barHeight * sc
        let barCenterY = size.height - safeTop - barH / 2

        // Bar background
        let headerBar       = SKShapeNode(rectOf: CGSize(width: size.width, height: barH))
        headerBar.position  = CGPoint(x: size.width / 2, y: barCenterY)
        headerBar.fillColor = config.barFill
        headerBar.strokeColor = .clear
        headerBar.zPosition = 1
        addChild(headerBar)

        // Bottom separator line
        let divider = GeometryForge.dividerLine(
            span: size.width,
            tint: DesignToken.radiantCrimson,
            opacity: 0.45
        )
        divider.position  = CGPoint(x: size.width / 2, y: barCenterY - barH / 2)
        divider.zPosition = 2
        addChild(divider)

        // Title label
        let titleNode = TypographyScale.labelNode(
            text:   config.titleText,
            size:   14 * sc,
            tint:   config.titleTint,
            weight: .headline
        )
        titleNode.position  = CGPoint(x: size.width / 2, y: barCenterY)
        titleNode.zPosition = 2
        addChild(titleNode)

        // Optional back button
        if config.showBackBtn, let action = config.backAction {
            mountScaffoldBackButton(
                centerY:  barCenterY,
                label:    config.backLabel,
                sc:       sc,
                action:   action
            )
        }

        return barCenterY - barH / 2
    }

    /// Mount a BACK button on the left side of the header.
    func mountScaffoldBackButton(
        centerY: CGFloat,
        label: String = "BACK",
        sc: CGFloat,
        action: @escaping () -> Void
    ) {
        let backBtn = ClaviculaNodelet(
            size:        CGSize(width: 72 * sc, height: 34 * sc),
            title:       label,
            fillColor:   DesignToken.violetShadow,
            titleColor:  DesignToken.frostSheen,
            cornerRadius: 8 * sc
        )
        backBtn.position  = CGPoint(x: 16 * sc + 36 * sc, y: centerY)
        backBtn.zPosition = 4
        backBtn.onImpact  = action
        addChild(backBtn)
    }
}
