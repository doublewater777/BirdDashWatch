import Foundation

enum GameState {
    case idle
    case playing
    case gameOver
}

enum GameEndReason {
    case crash
    case sessionComplete
}
