import CoreGraphics
import Foundation

struct Obstacle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var gapCenterY: CGFloat
    var gapHeight: CGFloat
    var width: CGFloat
    var hasScored: Bool = false

    func upperFrame(in playfield: CGSize) -> CGRect {
        let upperHeight = max(0, gapCenterY - (gapHeight / 2))
        return CGRect(x: x, y: 0, width: width, height: upperHeight)
    }

    func lowerFrame(in playfield: CGSize) -> CGRect {
        let lowerY = min(playfield.height, gapCenterY + (gapHeight / 2))
        return CGRect(x: x, y: lowerY, width: width, height: max(0, playfield.height - lowerY))
    }
}
