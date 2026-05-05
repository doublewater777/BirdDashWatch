import SwiftUI

struct GameOverView: View {
    let score: Int
    let bestScore: Int
    let isNewBest: Bool

    var body: some View {
        VStack(spacing: 8) {
            Spacer()

            Text("\(score)")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()

            Text(String(format: NSLocalizedString("best_score_format", comment: ""), bestScore))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.78))

            if isNewBest {
                Text("new_best")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.yellow)
            }

            Text("retry")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Color.green, in: Capsule())
                .padding(.top, 2)
                .allowsHitTesting(false)

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.black.opacity(0.35))
        .ignoresSafeArea()
    }
}
