// RunHistoryScene.swift — Game run history screen

import SpriteKit

class RunHistoryScene: SKScene {

    override func didMove(to view: SKView) {
        backgroundColor = PaletteForge.obsidian
        buildUI()
    }

    private func buildUI() {
        let sc = size.adaptiveScale
        let safeTop = view?.safeAreaInsets.top ?? 44
        let safeBot = view?.safeAreaInsets.bottom ?? 34

        // Background
        let bg = SKSpriteNode(imageNamed: "bg_main")
        bg.size = size
        bg.position = CGPoint(x: size.width/2, y: size.height/2)
        bg.alpha = 0.20
        bg.zPosition = -1
        addChild(bg)

        // ── Header ──────────────────────────────────────────────
        let headerH: CGFloat = 44 * sc
        let headerY = size.height - safeTop - headerH / 2

        let headerBg = SKShapeNode(rectOf: CGSize(width: size.width, height: headerH))
        headerBg.position = CGPoint(x: size.width / 2, y: headerY)
        headerBg.fillColor = UIColor(white: 0, alpha: 0.55)
        headerBg.strokeColor = .clear
        headerBg.zPosition = 1
        addChild(headerBg)

        let backBtn = ObsidianButtonNode(
            size: CGSize(width: 68 * sc, height: 34 * sc),
            title: "BACK",
            fillColor: PaletteForge.slateGray,
            titleColor: PaletteForge.ashWhite,
            cornerRadius: 8 * sc
        )
        backBtn.position = CGPoint(x: 16 * sc + 34 * sc, y: headerY)
        backBtn.zPosition = 4
        backBtn.onTap = { [weak self] in self?.goBack() }
        addChild(backBtn)

        let titleLbl = PaletteForge.makeLabel(text: "RUN HISTORY", fontSize: 14 * sc, color: PaletteForge.cinderGold, bold: true)
        titleLbl.position = CGPoint(x: size.width / 2, y: headerY)
        titleLbl.zPosition = 2
        addChild(titleLbl)

        // ── Summary strip ────────────────────────────────────────
        let store = RunArchiveStore.shared
        let stripY = headerY - headerH / 2 - 34 * sc
        let summaryLbl = PaletteForge.makeLabel(
            text: "Total: \(store.totalRuns)  |  Best: \(store.bestDays) days  |  Victories: \(store.totalVictories)  |  Zombies: \(store.totalZombies)",
            fontSize: 10 * sc,
            color: PaletteForge.ashWhite.withAlphaComponent(0.65)
        )
        summaryLbl.position = CGPoint(x: size.width / 2, y: stripY)
        summaryLbl.zPosition = 2
        addChild(summaryLbl)

        // ── Run rows ─────────────────────────────────────────────
        let runs = store.runs
        let rowH: CGFloat = 58 * sc
        let rowPad: CGFloat = 8 * sc
        let listTop = stripY - 22 * sc
        let listBot = safeBot + 20 * sc
        let visibleH = listTop - listBot
        let maxVisible = Int(visibleH / (rowH + rowPad))

        if runs.isEmpty {
            let emptyLbl = PaletteForge.makeLabel(
                text: "No runs yet. Survive the wasteland!",
                fontSize: 13 * sc,
                color: PaletteForge.ashWhite.withAlphaComponent(0.5)
            )
            emptyLbl.position = CGPoint(x: size.width / 2, y: size.height * 0.44)
            emptyLbl.zPosition = 2
            addChild(emptyLbl)
            return
        }

        let displayRuns = Array(runs.prefix(maxVisible))
        for (i, run) in displayRuns.enumerated() {
            let rowY = listTop - (rowH / 2) - CGFloat(i) * (rowH + rowPad)
            addChild(buildRunRow(run: run, index: i, sc: sc, rowY: rowY, rowH: rowH))
        }

        if runs.count > maxVisible {
            let moreLbl = PaletteForge.makeLabel(
                text: "+ \(runs.count - maxVisible) more runs",
                fontSize: 10 * sc,
                color: PaletteForge.ashWhite.withAlphaComponent(0.4)
            )
            moreLbl.position = CGPoint(x: size.width/2, y: safeBot + 14 * sc)
            moreLbl.zPosition = 2
            addChild(moreLbl)
        }
    }

    private func buildRunRow(run: RunRecord, index: Int, sc: CGFloat, rowY: CGFloat, rowH: CGFloat) -> SKNode {
        let rowW = size.width - 24 * sc
        let container = SKNode()

        let bg = PaletteForge.makeRoundedPanel(
            size: CGSize(width: rowW, height: rowH),
            cornerRadius: 10 * sc,
            fillColor: run.victory
                ? UIColor(red: 0.06, green: 0.14, blue: 0.09, alpha: 0.90)
                : UIColor(red: 0.10, green: 0.10, blue: 0.14, alpha: 0.90),
            strokeColor: run.victory
                ? PaletteForge.jadeTeal.withAlphaComponent(0.5)
                : PaletteForge.slateGray.withAlphaComponent(0.4),
            lineWidth: 1
        )
        container.addChild(bg)
        container.position = CGPoint(x: size.width / 2, y: rowY)
        container.zPosition = 2

        // Rank badge
        let rankLbl = PaletteForge.makeLabel(text: "#\(index + 1)", fontSize: 11 * sc, color: PaletteForge.ashWhite.withAlphaComponent(0.5))
        rankLbl.position = CGPoint(x: -rowW / 2 + 20 * sc, y: 0)
        container.addChild(rankLbl)

        // Outcome icon
        let iconLbl = PaletteForge.makeLabel(text: run.victory ? "🏆" : "💀", fontSize: 18 * sc)
        iconLbl.position = CGPoint(x: -rowW / 2 + 46 * sc, y: 0)
        container.addChild(iconLbl)

        // Class name
        let kindName: [String: String] = ["chirurgeon": "Doctor", "legionary": "Soldier", "artificer": "Engineer"]
        let className = kindName[run.archetypeKind] ?? run.archetypeKind.capitalized
        let classLbl = PaletteForge.makeLabel(text: className.uppercased(), fontSize: 10 * sc, color: PaletteForge.cinderGold, bold: true)
        classLbl.position = CGPoint(x: -rowW / 2 + 86 * sc, y: rowH * 0.12)
        classLbl.horizontalAlignmentMode = .left
        container.addChild(classLbl)

        // Stats
        let statsText = "Day \(run.daysSurvived)  ·  🧟 \(run.zombiesSlain)  ·  👥 \(run.survivorsMet)"
        let statsLbl = PaletteForge.makeLabel(text: statsText, fontSize: 10 * sc, color: PaletteForge.ashWhite.withAlphaComponent(0.75))
        statsLbl.position = CGPoint(x: -rowW / 2 + 86 * sc, y: -rowH * 0.22)
        statsLbl.horizontalAlignmentMode = .left
        container.addChild(statsLbl)

        // Date
        let df = DateFormatter()
        df.dateFormat = "MM/dd HH:mm"
        let dateLbl = PaletteForge.makeLabel(text: df.string(from: run.date), fontSize: 9 * sc, color: PaletteForge.ashWhite.withAlphaComponent(0.35))
        dateLbl.position = CGPoint(x: rowW / 2 - 8 * sc, y: 0)
        dateLbl.horizontalAlignmentMode = .right
        container.addChild(dateLbl)

        // Entrance
        container.alpha = 0
        container.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.06 * Double(index)),
            SKAction.fadeIn(withDuration: 0.22)
        ]))

        return container
    }

    private func goBack() {
        let scene = TitleVaultScene(size: size)
        scene.scaleMode = scaleMode
        view?.presentScene(scene, transition: SKTransition.push(with: .right, duration: 0.35))
    }
}
