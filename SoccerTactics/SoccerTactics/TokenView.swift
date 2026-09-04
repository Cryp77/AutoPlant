import SwiftUI

/// A draggable player marker or ball, positioned in its parent's coordinate space.
struct TokenView: View {
    @Binding var token: PlayerToken
    var onDelete: () -> Void

    @GestureState private var dragOffset: CGSize = .zero

    var body: some View {
        ZStack {
            Circle()
                .fill(token.kind.color)
                .overlay(Circle().stroke(.white, lineWidth: 2))
                .frame(width: token.kind.size, height: token.kind.size)

            if token.kind != .ball {
                Text(token.label)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .position(x: token.position.x + dragOffset.width, y: token.position.y + dragOffset.height)
        .shadow(radius: 2)
        .gesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in
                    state = value.translation
                }
                .onEnded { value in
                    token.position.x += value.translation.width
                    token.position.y += value.translation.height
                }
        )
        .onTapGesture(count: 2) { onDelete() }
    }
}
