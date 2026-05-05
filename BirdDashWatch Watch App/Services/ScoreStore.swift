import Foundation

struct ScoreStore {
    private let bestScoreKey = "best-score"

    func loadBestScore() -> Int {
        UserDefaults.standard.integer(forKey: bestScoreKey)
    }

    func save(bestScore: Int) {
        UserDefaults.standard.set(bestScore, forKey: bestScoreKey)
    }
}
