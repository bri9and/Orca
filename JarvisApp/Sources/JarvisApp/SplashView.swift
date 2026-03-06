import SwiftUI

struct SplashView: View {
    @ObservedObject var serverManager: ServerManager

    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                // Animated solar system icon
                ZStack {
                    // Orbit rings
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        .frame(width: 80, height: 80)
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        .frame(width: 120, height: 120)

                    // Central star
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.yellow, .orange],
                                center: .center,
                                startRadius: 0,
                                endRadius: 15
                            )
                        )
                        .frame(width: 24, height: 24)
                        .shadow(color: .yellow.opacity(0.5), radius: 10)

                    // Orbiting planet
                    Circle()
                        .fill(Color.cyan)
                        .frame(width: 8, height: 8)
                        .shadow(color: .cyan.opacity(0.6), radius: 4)
                        .offset(x: 40)
                        .rotationEffect(.degrees(rotation))
                }
                .frame(width: 140, height: 140)

                Text("JARVIS")
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .kerning(6)

                if let error = serverManager.errorMessage {
                    Text(error)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    Button("Retry") {
                        serverManager.restart()
                    }
                    .buttonStyle(.bordered)
                    .tint(.cyan)
                } else {
                    Text("Starting server...")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}
