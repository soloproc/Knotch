import SwiftUI

/// Every number in this app's UI is measured off the Figma frame in
/// `docs/design/frame-124-hover-tooltip.png` (2000 x 2000 px), so the layout is
/// *proportionally* exact rather than eyeballed.
///
/// The frame fixes only ratios, never an absolute size, so one anchor picks the
/// scale: the design spec calls the provider ring 44pt across, and it measures
/// 117px in the frame. Change `scale` and the whole surface — notch, rings,
/// type, tooltip — resizes together, still in the design's proportions.
enum Design {
    /// The original shipped scale, kept as the 100 % reference.
    static let baseScale: CGFloat = 44.0 / 117.0
    /// UserDefaults key for the chosen scale multiplier.
    static let scaleKey = "notchScale"

    /// Points per pixel of the design frame.
    ///
    /// Reads the multiplier from `UserDefaults` (stored as `notchScale`) and
    /// multiplies it by `baseScale`, so 1.0 means the original design size and
    /// 0.82 means 82 % of it.
    static var scale: CGFloat {
        let saved = UserDefaults.standard.double(forKey: scaleKey)
        let multiplier = saved > 0 ? CGFloat(saved) : 0.82
        return baseScale * multiplier
    }

    /// A distance measured in design-frame pixels, in points.
    static func px(_ pixels: CGFloat) -> CGFloat { pixels * scale }

    /// Cap-height fraction of an em for SF Pro. Text in the frame can only be
    /// measured by its cap height, so this converts back to a point size.
    private static let capRatio: CGFloat = 0.714

    /// The point size whose capital letters are `pixels` tall in the frame.
    static func fontSize(capPixels pixels: CGFloat) -> CGFloat {
        px(pixels) / capRatio
    }
}
