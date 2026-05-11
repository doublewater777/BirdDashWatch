import SwiftUI

struct GameOverView: View {
    let score: Int
    let bestScore: Int
    let isNewBest: Bool
    let endReason: GameEndReason
    let isDailyChallenge: Bool
    let onRetry: () -> Void
    let onBackHome: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Spacer()

            VStack(spacing: 6) {
                Text(titleKey)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(titleColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(titleColor.opacity(0.18), in: Capsule())

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

                if isDailyChallenge {
                    Text(subtitleKey)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 6)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.black.opacity(0.10), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(.white.opacity(0.08), lineWidth: 0.8)
            }

            HStack(spacing: 6) {
                Button(action: onRetry) {
                    Text("retry")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            LinearGradient(
                                colors: [Color.green, Color.green.opacity(0.78)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: Capsule()
                        )
                }
                .buttonStyle(.plain)

                Button(action: onBackHome) {
                    Text("home")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.92))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(.white.opacity(0.14), in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 2)

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.52), Color.black.opacity(0.30)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .ignoresSafeArea()
    }

    private var titleKey: LocalizedStringKey {
        switch endReason {
        case .crash:
            return "game_over_title"
        case .sessionComplete:
            return "daily_complete_title"
        }
    }

    private var subtitleKey: LocalizedStringKey {
        switch endReason {
        case .crash:
            return "daily_try_again"
        case .sessionComplete:
            return "daily_complete_subtitle"
        }
    }

    private var titleColor: Color {
        switch endReason {
        case .crash:
            return .orange
        case .sessionComplete:
            return .green
        }
    }
}
