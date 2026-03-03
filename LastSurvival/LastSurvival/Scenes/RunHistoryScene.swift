// RunHistoryScene.swift — Game run history (refactored)

import SpriteKit

// MARK: - RunRowViewModel: display model for one run-history row
private struct RunRowViewModel {
    let rankLabel:   String
    let outcomeIcon: String
    let className:   String
    let statsLine:   String
    let dateText:    String
    let isVictory:   Bool

    static func from(record: RunRecord, rank: Int) -> RunRowViewModel {
        let classNameMap: [String: String] = [
            "salver": "DOCTOR", "pikeman": "SOLDIER", "tinker": "ENGINEER",
            "chirurgeon": "DOCTOR", "legionary": "SOLDIER", "artificer": "ENGINEER"
        ]
        let formatter        = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        return RunRowViewModel(
            rankLabel:   "#\(rank)",
            outcomeIcon: record.victory ? "🏆" : "💀",
            className:   classNameMap[record.archetypeKind] ?? record.archetypeKind.uppercased(),
            statsLine:   "Day \(record.daysSurvived)  ·  🧟 \(record.zombiesSlain)  ·  👥 \(record.survivorsMet)",
            dateText:    formatter.string(from: record.date),
            isVictory:   record.victory
        )
    }
}

// MARK: - SummaryBanner: aggregated stats strip above the list
private class SummaryBanner {
    private let archive: AnnalsDepository

    init(archive: AnnalsDepository) { self.archive = archive }

    func buildLabel(centerX: CGFloat, centerY: CGFloat, scale sc: CGFloat) -> SKNode {
        let stats   = archive.statistics
        let content = "TOTAL: \(stats.totalRunCount)  |  BEST: \(stats.bestDaysCount) DAYS  |  VICTORIES: \(stats.victoryCount)"
        let label   = TypographyScale.labelNode(text: content, size: 9 * sc, tint: DesignToken.ashNebula)
        label.position  = CGPoint(x: centerX, y: centerY)
        label.zPosition = 2
        return label
    }
}

// MARK: - HistoryRowBuilder: builds a single run-row node
private class HistoryRowBuilder {
    private let viewModel:  RunRowViewModel
    private let rowWidth:   CGFloat
    private let rowHeight:  CGFloat
    private let scale:      CGFloat

    init(viewModel: RunRowViewModel, width: CGFloat, height: CGFloat, scale: CGFloat) {
        self.viewModel = viewModel
        self.rowWidth  = width
        self.rowHeight = height
        self.scale     = scale
    }

    func build() -> SKNode {
        let sc       = scale
        let vm       = viewModel
        let rowNode  = SKNode()

        let borderTint = vm.isVictory
            ? DesignToken.phosphorLime.withAlphaComponent(0.55)
            : DesignToken.violetShadow.withAlphaComponent(0.50)
        let fillTint = vm.isVictory
            ? UIColor(red: 0.04, green: 0.14, blue: 0.06, alpha: 0.88)
            : UIColor(red: 0.08, green: 0.05, blue: 0.18, alpha: 0.88)

        let panel = GeometryForge.panelNode(
            size:        CGSize(width: rowWidth, height: rowHeight),
            cutDepth:    8,
            fill:        fillTint,
            stroke:      borderTint,
            strokeWidth: 1.5
        )
        rowNode.addChild(panel)

        // Rank number
        let rankNode = TypographyScale.labelNode(text: vm.rankLabel, size: 10 * sc, tint: DesignToken.ashNebula)
        rankNode.position = CGPoint(x: -rowWidth / 2 + 20 * sc, y: 0)
        rowNode.addChild(rankNode)

        // Outcome icon
        let iconNode = TypographyScale.labelNode(text: vm.outcomeIcon, size: 18 * sc)
        iconNode.position = CGPoint(x: -rowWidth / 2 + 46 * sc, y: 0)
        rowNode.addChild(iconNode)

        // Class name
        let classColorTint = vm.isVictory ? DesignToken.phosphorLime : DesignToken.radiantCrimson
        let classNode      = TypographyScale.labelNode(text: vm.className, size: 10 * sc, tint: classColorTint, weight: .headline)
        classNode.position                = CGPoint(x: -rowWidth / 2 + 86 * sc, y: rowHeight * 0.12)
        classNode.horizontalAlignmentMode = .left
        rowNode.addChild(classNode)

        // Stats line
        let statsNode = TypographyScale.labelNode(
            text: vm.statsLine,
            size: 10 * sc,
            tint: DesignToken.frostSheen.withAlphaComponent(0.72)
        )
        statsNode.position                = CGPoint(x: -rowWidth / 2 + 86 * sc, y: -rowHeight * 0.22)
        statsNode.horizontalAlignmentMode = .left
        rowNode.addChild(statsNode)

        // Date label (right edge)
        let dateNode = TypographyScale.labelNode(text: vm.dateText, size: 9 * sc, tint: DesignToken.ashNebula)
        dateNode.position                = CGPoint(x: rowWidth / 2 - 8 * sc, y: 0)
        dateNode.horizontalAlignmentMode = .right
        rowNode.addChild(dateNode)

        return rowNode
    }
}

// MARK: - RunHistoryScene
class RunHistoryScene: SKScene {

    override func didMove(to view: SKView) {
        backgroundColor = DesignToken.cosmicInk
        assembleInterface()
    }

    private func assembleInterface() {
        let sc      = size.calibration
        let safeTop = view?.safeAreaInsets.top    ?? 44
        let safeBot = view?.safeAreaInsets.bottom ?? 34

        mountBackground(sc: sc)
        let headerEdgeY = mountHeader(sc: sc, safeTop: safeTop)
        mountSummaryBanner(sc: sc, headerEdgeY: headerEdgeY)
        mountRunList(sc: sc, headerEdgeY: headerEdgeY, safeBot: safeBot)
    }

    private func mountBackground(sc: CGFloat) {
        let wallpaper       = SKSpriteNode(imageNamed: "bg_main")
        wallpaper.size      = size
        wallpaper.position  = CGPoint(x: size.width / 2, y: size.height / 2)
        wallpaper.alpha     = 0.12
        wallpaper.zPosition = -1
        addChild(wallpaper)

        let dim       = SKShapeNode(rectOf: size)
        dim.position  = CGPoint(x: size.width / 2, y: size.height / 2)
        dim.fillColor = UIColor(red: 0.03, green: 0.02, blue: 0.14, alpha: 0.65)
        dim.strokeColor = .clear
        dim.zPosition = 0
        addChild(dim)
    }

    // Returns the bottom Y of the header bar
    private func mountHeader(sc: CGFloat, safeTop: CGFloat) -> CGFloat {
        let barH   = 46 * sc
        let barCenterY = size.height - safeTop - barH / 2

        let headerBar       = SKShapeNode(rectOf: CGSize(width: size.width, height: barH))
        headerBar.position  = CGPoint(x: size.width / 2, y: barCenterY)
        headerBar.fillColor = UIColor(red: 0.06, green: 0.03, blue: 0.18, alpha: 0.92)
        headerBar.strokeColor = .clear
        headerBar.zPosition = 1
        addChild(headerBar)

        let divider = GeometryForge.dividerLine(span: size.width, tint: DesignToken.radiantCrimson, opacity: 0.45)
        divider.position  = CGPoint(x: size.width / 2, y: barCenterY - barH / 2)
        divider.zPosition = 2
        addChild(divider)

        let backBtn = ObsidianButtonNode(
            size:        CGSize(width: 72 * sc, height: 34 * sc),
            title:       "BACK",
            fillColor:   DesignToken.violetShadow,
            titleColor:  DesignToken.frostSheen,
            cornerRadius: 8 * sc
        )
        backBtn.position  = CGPoint(x: 16 * sc + 36 * sc, y: barCenterY)
        backBtn.zPosition = 4
        backBtn.onTap     = { [weak self] in self?.returnToMenu() }
        addChild(backBtn)

        let titleNode = TypographyScale.labelNode(
            text:   "RUN HISTORY",
            size:   14 * sc,
            tint:   DesignToken.ceruleanVolt,
            weight: .headline
        )
        titleNode.position  = CGPoint(x: size.width / 2, y: barCenterY)
        titleNode.zPosition = 2
        addChild(titleNode)

        return barCenterY - barH / 2
    }

    private func mountSummaryBanner(sc: CGFloat, headerEdgeY: CGFloat) {
        let bannerY = headerEdgeY - 28 * sc
        let label = SummaryBanner(archive: AnnalsDepository.shared)
            .buildLabel(centerX: size.width / 2, centerY: bannerY, scale: sc)
        addChild(label)
    }

    private func mountRunList(sc: CGFloat, headerEdgeY: CGFloat, safeBot: CGFloat) {
        let allRuns       = AnnalsDepository.shared.runs
        let rowH: CGFloat = 60 * sc
        let rowGap: CGFloat = 8 * sc
        let listTopY      = headerEdgeY - 18 * sc - 28 * sc
        let listBottomY   = safeBot + 20 * sc
        let maxVisible    = Int((listTopY - listBottomY) / (rowH + rowGap))

        guard !allRuns.isEmpty else {
            let empty = TypographyScale.labelNode(
                text: "No runs yet. Survive the wasteland!",
                size: 13 * sc,
                tint: DesignToken.ashNebula
            )
            empty.position  = CGPoint(x: size.width / 2, y: size.height * 0.44)
            empty.zPosition = 2
            addChild(empty)
            return
        }

        let displayed = Array(allRuns.prefix(maxVisible))
        displayed.enumerated().forEach { idx, record in
            let vm      = RunRowViewModel.from(record: record, rank: idx + 1)
            let builder = HistoryRowBuilder(
                viewModel: vm,
                width:     size.width - 24 * sc,
                height:    rowH,
                scale:     sc
            )
            let rowNode       = builder.build()
            let rowCenterY    = listTopY - rowH / 2 - CGFloat(idx) * (rowH + rowGap)
            rowNode.position  = CGPoint(x: size.width / 2, y: rowCenterY)
            rowNode.zPosition = 2
            rowNode.alpha     = 0
            rowNode.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.05 * Double(idx)),
                SKAction.fadeIn(withDuration: 0.22)
            ]))
            addChild(rowNode)
        }

        if allRuns.count > maxVisible {
            let surplus  = allRuns.count - maxVisible
            let overflow = TypographyScale.labelNode(
                text: "+ \(surplus) MORE RUNS",
                size: 9 * sc,
                tint: DesignToken.ashNebula
            )
            overflow.position  = CGPoint(x: size.width / 2, y: safeBot + 14 * sc)
            overflow.zPosition = 2
            addChild(overflow)
        }
    }

    private func returnToMenu() {
        let menu = TitleVaultScene(size: size)
        menu.scaleMode = scaleMode
        view?.presentScene(menu, transition: SKTransition.push(with: .right, duration: 0.35))
    }

    private func goBack() { returnToMenu() }
}

typealias ChronolithScrollScene = RunHistoryScene
