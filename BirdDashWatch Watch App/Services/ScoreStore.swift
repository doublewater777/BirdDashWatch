import Foundation

struct ScoreStore {
    private let bestScoreKey = "best-score"
    private let dailyBestPrefix = "daily-best-"

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    func loadBestScore() -> Int {
        UserDefaults.standard.integer(forKey: bestScoreKey)
    }

    func save(bestScore: Int) {
        UserDefaults.standard.set(bestScore, forKey: bestScoreKey)
    }

    func todayDateString() -> String {
        Self.dateFormatter.string(from: Date())
    }

    func dailySeed() -> Int {
        todayDateString().utf8.reduce(0) { seed, byte in
            seed &* 31 &+ Int(byte)
        }
    }

    func loadDailyBest() -> Int {
        let key = dailyBestPrefix + todayDateString()
        return UserDefaults.standard.integer(forKey: key)
    }

    func saveDailyBest(_ score: Int) {
        let key = dailyBestPrefix + todayDateString()
        let current = UserDefaults.standard.integer(forKey: key)
        if score > current {
            UserDefaults.standard.set(score, forKey: key)
        }
    }
}
