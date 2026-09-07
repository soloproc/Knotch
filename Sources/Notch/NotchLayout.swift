import AppKit

/// Every measurement is quoted in design-frame pixels so it can be checked
/// against `docs/design/frame-124-hover-tooltip.png` directly.
enum NotchLayout {
    // MARK: - Mutable layout constants (recomputed when Design.scale changes)

    /// The depth the design frame fixes: a 44pt ring with an even margin
    /// either side of it.
    static var sideBodyDepth: CGFloat = 0

    static var curlRadius: CGFloat = 0
    static var bezelFillet: CGFloat = 0
    static var cornerRadius: CGFloat = 0
    static var padTop: CGFloat = 0
    static var padBottom: CGFloat = 0
    static var cellSpacing: CGFloat = 0

    // The resting pill
    static var pillWidth: CGFloat = 0
    static var pillHeight: CGFloat = 0
    static var pillHotZone: CGFloat = 0

    // A provider cell
    static var ringDiameter: CGFloat = 0
    static var trackStroke: CGFloat = 0
    static var progressStroke: CGFloat = 0
    static var glyphSize: CGFloat = 0
    static var ringLabelGap: CGFloat = 0

    // The activity indicator
    static var activityDiameter: CGFloat = 0
    static var activityStroke: CGFloat = 0

    // The settings orb
    static var orbDiameter: CGFloat = 0
    static var orbStroke: CGFloat = 0
    static var orbGap: CGFloat = 0

    // The hover tooltip
    static var cardWidth: CGFloat = 0
    static var cardCorner: CGFloat = 0
    static var cardPadding: CGFloat = 0
    static var tailLength: CGFloat = 0
    static var tailHeight: CGFloat = 0
    static var tailGap: CGFloat = 0
    static var barHeight: CGFloat = 0
    static var headerGap: CGFloat = 0
    static var headerToBlock: CGFloat = 0
    static var labelToBar: CGFloat = 0
    static var barToUsed: CGFloat = 0
    static var blockSpacing: CGFloat = 0
    static var sessionRowGap: CGFloat = 0
    static var statusDot: CGFloat = 0
    static var statusDotStroke: CGFloat = 0
    static var statusDotGap: CGFloat = 0
    static var hairline: CGFloat = 0

    /// The percent label's line box.
    static var percentLineHeight: CGFloat = 0
    static var cardTitleLineHeight: CGFloat = 0
    static var cardBodyFont: NSFont = NSFont.systemFont(ofSize: 12)
    static var cardBodyLineHeight: CGFloat = 0
    static var defaultMaxCardHeight: CGFloat = 0

    // MARK: - Immutable constants

    /// The busiest provider that occurs — Claude, with four limit windows.
    static let maxWindowCount = 4
    /// Past this many rows the list has stopped being glanceable.
    static let sessionCeiling = 12
    /// What to assume before the panel knows which screen it is on.
    static let defaultSessionCap = 4

    // MARK: - Recompute

    /// Recalculate every layout constant from the current `Design.scale`.
    /// Called at launch and whenever the user changes the size in Settings.
    static func recompute() {
        sideBodyDepth = Design.px(186)
        curlRadius    = Design.px(103)
        bezelFillet   = Design.px(28)
        cornerRadius  = Design.px(78.8)
        padTop        = Design.px(69.5)
        padBottom     = Design.px(50.1)
        cellSpacing   = Design.px(83.5)

        pillWidth  = Design.px(26)
        pillHeight = Design.px(210)
        pillHotZone = Design.px(90)

        ringDiameter  = Design.px(117)
        trackStroke   = Design.px(15.5)
        progressStroke = Design.px(8)
        glyphSize     = Design.px(46)
        ringLabelGap  = Design.px(26.9)

        activityDiameter = Design.px(72)
        activityStroke   = Design.px(5.5)

        orbDiameter = Design.px(124)
        orbStroke   = Design.px(18)
        orbGap      = Design.px(27)

        cardWidth    = Design.px(600)
        cardCorner   = Design.px(49.5)
        cardPadding  = Design.px(32)
        tailLength   = Design.px(75)
        tailHeight   = Design.px(87)
        tailGap      = Design.px(28)
        barHeight    = Design.px(10.5)
        headerGap    = Design.px(17)
        headerToBlock = Design.px(21)
        labelToBar   = Design.px(16.8)
        barToUsed    = Design.px(17.8)
        blockSpacing = Design.px(20)
        sessionRowGap = Design.px(10)
        statusDot    = Design.px(17)
        statusDotStroke = Design.px(3.4)
        statusDotGap = Design.px(11)
        hairline     = Design.px(2.5)

        let pctFont = NSFont.systemFont(ofSize: Design.fontSize(capPixels: 27), weight: .semibold)
        percentLineHeight = ceil(pctFont.ascender - pctFont.descender + pctFont.leading)

        let titleFont = NSFont.systemFont(ofSize: Design.fontSize(capPixels: 26), weight: .semibold)
        cardTitleLineHeight = ceil(titleFont.ascender - titleFont.descender + titleFont.leading)

        cardBodyFont = NSFont.systemFont(ofSize: Design.fontSize(capPixels: 18), weight: .regular)
        cardBodyLineHeight = ceil(cardBodyFont.ascender - cardBodyFont.descender + cardBodyFont.leading)

        defaultMaxCardHeight = maxCardHeight(sessionCap: defaultSessionCap)
    }

    // MARK: - Computed helpers (depend on mutable constants above)

    /// How deep the notch is, which is **not** the same on every edge.
    static func bodyDepth(for edge: NotchEdge) -> CGFloat {
        edge.isVertical ? sideBodyDepth : 2 * sideRingMargin + cellExtent
    }

    /// Clear space between the ring and the bezel, from the design frame.
    private static var sideRingMargin: CGFloat { (sideBodyDepth - ringDiameter) / 2 }

    /// The same margin on every edge — on a horizontal one it is the gap above
    /// the ring rather than beside it, but it is the same distance.
    static func ringMargin(for edge: NotchEdge) -> CGFloat { sideRingMargin }

    /// What the arc scales to as it hides.
    static var orbMergeScale: CGFloat { (curlRadius + orbStroke) / orbArcRadius }
    /// Radius of the resting arc: the flare's radius, less the gap.
    static var orbArcRadius: CGFloat { curlRadius - orbGap }
    /// The resting arc's circle when it traces a *convex* corner.
    static func orbConvexArcRadius(corner: CGFloat) -> CGFloat { corner + orbGap }
    /// How far off a convex corner the orb hangs, on each axis.
    static func orbCornerOffset(corner: CGFloat) -> CGFloat {
        (corner + orbGap + orbDiameter / 2) / 2.0.squareRoot()
    }
    static var orbGlyph: CGFloat { Design.px(56) }
    static var orbHotZone: CGFloat { Design.px(152) }

    /// Room at each end of the stack: enough for the settings orb to hang past
    /// the foot of the shape, and enough for a tooltip anchored to the first or
    /// last cell to still have somewhere to sit.
    static func slack(for edge: NotchEdge,
                      maxCardHeight: CGFloat = defaultMaxCardHeight) -> CGFloat {
        edge.isVertical
            ? max(endSlack, maxCardHeight / 2 + cardCorner)
            : max(endSlack, cardWidth / 2 + cardCorner)
    }
    private static let endSlack = Design.px(190)

    /// How wide a line of body text is inside the card.
    static var cardTextWidth: CGFloat { cardWidth - 2 * cardPadding }

    /// How tall a run of body text is once it has wrapped to that column.
    static func bodyTextHeight(_ text: String) -> CGFloat {
        guard !text.isEmpty else { return cardBodyLineHeight }
        let bounds = (text as NSString).boundingRect(
            with: CGSize(width: cardTextWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: cardBodyFont]
        )
        let lines = max(1, Int((bounds.height / cardBodyLineHeight).rounded(.up)))
        return CGFloat(lines) * cardBodyLineHeight
    }

    /// Ring plus its percent label.
    static var cellExtent: CGFloat { ringDiameter + ringLabelGap + percentLineHeight }

    /// What one cell claims along the stack.
    static func cellAlong(for edge: NotchEdge) -> CGFloat {
        edge.isVertical ? cellExtent : ringDiameter
    }

    /// Ring centre to ring centre.
    static func cellPitch(for edge: NotchEdge) -> CGFloat {
        cellAlong(for: edge) + cellSpacing
    }

    /// Padding at the start and the end of the stack.
    static func padStart(for edge: NotchEdge) -> CGFloat {
        edge.isVertical ? padTop : (padTop + padBottom) / 2
    }
    static func padEnd(for edge: NotchEdge) -> CGFloat {
        edge.isVertical ? padBottom : (padTop + padBottom) / 2
    }

    /// Distance from the start of the whole shape to cell `index`'s ring centre.
    static func ringCenter(index: Int, edge: NotchEdge = .right,
                           flare: CGFloat = curlRadius) -> CGFloat {
        flare + padStart(for: edge) + ringDiameter / 2
            + CGFloat(index) * cellPitch(for: edge)
    }

    /// Height of the notch body for a given number of provider cells.
    static func bodyLength(cellCount: Int, edge: NotchEdge = .right) -> CGFloat {
        let start = padStart(for: edge), end = padEnd(for: edge)
        guard cellCount > 0 else { return start + end }
        return start
            + CGFloat(cellCount) * cellAlong(for: edge)
            + CGFloat(cellCount - 1) * cellSpacing
            + end
    }

    /// Centre of the settings orb.
    static func orbCenterAlong(cellCount: Int, edge: NotchEdge = .right) -> CGFloat {
        shapeLength(cellCount: cellCount, edge: edge)
    }
    static var orbInsetFromEdge: CGFloat { curlRadius }

    /// Full shape length, flares included.
    static func shapeLength(cellCount: Int, edge: NotchEdge = .right,
                            flare: CGFloat = curlRadius) -> CGFloat {
        bodyLength(cellCount: cellCount, edge: edge) + 2 * flare
    }

    /// The tooltip's height for a given number of limit windows and live sessions.
    static func cardHeight(windowCount: Int, sessionCount: Int = 0,
                           sessionCap: Int = defaultSessionCap,
                           statusMessage: String? = nil,
                           blockMessage: String? = nil) -> CGFloat {
        let header = max(glyphSize, cardTitleLineHeight)
        var height = 2 * cardPadding + header

        if let blockMessage {
            height += headerToBlock + bodyTextHeight(blockMessage)
        }

        if windowCount > 0 {
            let block = 2 * cardBodyLineHeight + labelToBar + barHeight + barToUsed
            height += headerToBlock
                + CGFloat(windowCount) * block
                + CGFloat(windowCount - 1) * blockSpacing
        } else {
            height += headerToBlock + bodyTextHeight(statusMessage ?? "")
        }

        if sessionCount > 0 {
            let shown = min(sessionCount, max(0, sessionCap))
            let row = 2 * cardBodyLineHeight + sessionRowGap
            height += blockSpacing + hairline + blockSpacing
                + CGFloat(shown) * row
                + CGFloat(max(0, shown - 1)) * blockSpacing
            if sessionCount > shown {
                height += blockSpacing + cardBodyLineHeight
            }
        }
        return height
    }

    /// How many sessions a tooltip may list here before it has to summarise
    /// the rest.
    static func sessionsFitting(cardBudget: CGFloat, windowCount: Int) -> Int {
        var fits = 0
        for n in 1...sessionCeiling {
            let height = cardHeight(windowCount: windowCount,
                                    sessionCount: n + 1, sessionCap: n)
            guard height <= cardBudget else { break }
            fits = n
        }
        return fits
    }

    /// How tall the tallest card may be before the panel runs off the screen.
    static func maxCardHeight(sessionCap: Int) -> CGFloat {
        cardHeight(windowCount: maxWindowCount,
                   sessionCount: sessionCap + 1, sessionCap: sessionCap)
    }

    /// How far the panel reaches inward from the bezel, past the notch itself.
    static func tooltipDepth(for edge: NotchEdge,
                             maxCardHeight: CGFloat = defaultMaxCardHeight) -> CGFloat {
        (edge.isVertical ? cardWidth : maxCardHeight) + tailLength + tailGap
    }
}

// Trigger the initial computation the first time the type is touched.
private let _notchLayoutInitializer: Void = NotchLayout.recompute()
