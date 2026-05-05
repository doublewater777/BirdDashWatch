import CoreGraphics

struct Bird {
    var x: CGFloat
    var y: CGFloat
    var velocity: CGFloat
    var size: CGSize

    var frame: CGRect {
        CGRect(
            x: x - (size.width / 2),
            y: y - (size.height / 2),
            width: size.width,
            height: size.height
        )
    }

    static func makeDefault(in playfield: CGSize) -> Bird {
        Bird(
            x: playfield.width * 0.33,
            y: playfield.height * 0.5,
            velocity: 0,
            size: CGSize(width: 18, height: 18)
        )
    }
}
