import CoreGraphics

enum Collision {
    static func hits(bird: Bird, obstacle: Obstacle, in playfield: CGSize) -> Bool {
        bird.frame.intersects(obstacle.upperFrame(in: playfield)) ||
        bird.frame.intersects(obstacle.lowerFrame(in: playfield))
    }

    static func isOutOfBounds(bird: Bird, in playfield: CGSize) -> Bool {
        bird.frame.minY <= 0 || bird.frame.maxY >= playfield.height
    }
}
