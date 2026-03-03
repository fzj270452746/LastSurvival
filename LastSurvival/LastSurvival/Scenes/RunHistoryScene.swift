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

        let rankNode = TypographyScale.labelNode(text: vm.rankLabel, size: 10 * sc, tint: DesignToken.ashNebula)
        rankNode.position = CGPoint(x: -rowWidth / 2 + 20 * sc, y: 0)
        rowNode.addChild(rankNode)

        let iconNode = TypographyScale.labelNode(text: vm.outcomeIcon, size: 18 * sc)
        iconNode.position = CGPoint(x: -rowWidth / 2 + 46 * sc, y: 0)
        rowNode.addChild(iconNode)

        let classColorTint = vm.isVictory ? DesignToken.phosphorLime : DesignToken.radiantCrimson
        let classNode      = TypographyScale.labelNode(text: vm.className, size: 10 * sc, tint: classColorTint, weight: .headline)
        classNode.position                = CGPoint(x: -rowWidth / 2 + 86 * sc, y: rowHeight * 0.12)
        classNode.horizontalAlignmentMode = .left
        rowNode.addChild(classNode)

        let statsNode = TypographyScale.labelNode(
            text: vm.statsLine,
            size: 10 * sc,
            tint: DesignToken.frostSheen.withAlphaComponent(0.72)
        )
        statsNode.position                = CGPoint(x: -rowWidth / 2 + 86 * sc, y: -rowHeight * 0.22)
        statsNode.horizontalAlignmentMode = .left
        rowNode.addChild(statsNode)

        let dateNode = TypographyScale.labelNode(text: vm.dateText, size: 9 * sc, tint: DesignToken.ashNebula)
        dateNode.position                = CGPoint(x: rowWidth / 2 - 8 * sc, y: 0)
        dateNode.horizontalAlignmentMode = .right
        rowNode.addChild(dateNode)

        return rowNode
    }
}

// MARK: - RunHistoryScene: inherits ProstyleProscenium (Template Method)
class RunHistoryScene: ProstyleProscenium {

    override func didMove(to view: SKView) {
        // Configure header before calling super (which runs the template)
        headerConfig = ProsceniumHeaderConfig.standard(
            title: "RUN HISTORY",
            tint:  DesignToken.ceruleanVolt,
            back:  { [weak self] in self?.returnToMenu() }
        )
        super.didMove(to: view)
    }

    // MARK: - Template Method override: scene-specific content
    override func buildContent() {
        let sc      = displayScale
        let safeBot = safeBottomInset
        mountSummaryBanner(sc: sc, headerEdgeY: headerBottomY)
        mountRunList(sc: sc, headerEdgeY: headerBottomY, safeBot: safeBot)
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
        dispatchEgress(RetreatEgress())
    }

    private func goBack() { returnToMenu() }
}

typealias ChronolithScrollScene = RunHistoryScene
