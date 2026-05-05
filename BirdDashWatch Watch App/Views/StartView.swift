import SwiftUI

struct StartView: View {
    let bestScore: Int
    @State private var birdOffset: CGFloat = -4

    var body: some View {
        VStack(spacing: 10) {
            floatingBird

            VStack(spacing: 4) {
                Text("Bird Dash")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text("Best \(bestScore)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.82))
            }

            Text("Start")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.vertical, 7)
                .padding(.horizontal, 18)
                .background(Color.orange, in: Capsule())
                .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 18)
        .background(.black.opacity(0.18))
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
}
