import SwiftUI

struct StartView: View {
    let bestScore: Int
    let dailyBest: Int
    let onDailyChallenge: () -> Void
    let onNormalGame: () -> Void
    @State private var birdOffset: CGFloat = -4

    var body: some View {
        VStack(spacing: 9) {
            floatingBird

            VStack(spacing: 4) {
                Text("game_title")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(String(format: NSLocalizedString("best_score_format", comment: ""), bestScore))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.82))
            }

            VStack(spacing: 7) {
                modeButton(
                    action: onDailyChallenge,
                    icon: "calendar",
                    titleKey: "daily_challenge",
                    subtitleKey: "daily_mode_hint",
                    accent: Color.blue,
                    trailingText: dailyBest > 0 ? String(format: NSLocalizedString("today_best_format", comment: ""), dailyBest) : NSLocalizedString("daily_duration_hint", comment: "")
                )

                modeButton(
                    action: onNormalGame,
                    icon: "bolt.fill",
                    titleKey: "start",
                    subtitleKey: "normal_mode_hint",
                    accent: Color.orange,
                    trailingText: nil
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 18)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.14), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                birdOffset = 4
            }
        }
    }

    private var floatingBird: some View {
        Circle()
            .fill(Color.yellow)
            .frame(width: 18, height: 18)
            .overlay(alignment: .trailing) {
                Circle()
                    .fill(.white)
                    .frame(width: 4, height: 4)
                    .offset(x: -2)
            }
            .overlay(alignment: .bottomLeading) {
                Capsule()
                    .fill(Color.orange)
                    .frame(width: 7, height: 3)
                    .rotationEffect(.degrees(18))
                    .offset(x: 1, y: 3)
            }
            .shadow(color: .black.opacity(0.16), radius: 3, x: 0, y: 2)
            .offset(y: birdOffset)
    }

    private func modeButton(
        action: @escaping () -> Void,
        icon: String,
        titleKey: LocalizedStringKey,
        subtitleKey: LocalizedStringKey,
        accent: Color,
        trailingText: String?
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .frame(width: 24, height: 24)
                    .background(.white.opacity(0.16), in: Circle())

                VStack(alignment: .leading, spacing: 1) {
                    Text(titleKey)
                        .font(.caption.weight(.bold))

                    Text(subtitleKey)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.72))
                        .lineLimit(1)
                }

                Spacer(minLength: 6)

                if let trailingText {
                    Text(trailingText)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(.white.opacity(0.12), in: Capsule())
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    colors: [accent.opacity(0.96), accent.opacity(0.72)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .frame(minHeight: 66)
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 0.8)
            }
            .shadow(color: accent.opacity(0.16), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}
