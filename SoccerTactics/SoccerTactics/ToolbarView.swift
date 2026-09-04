import SwiftUI

struct ToolbarView: View {
    @Binding var tool: DrawTool
    @Binding var color: Color
    @Binding var lineWidth: CGFloat
    var onAddToken: (TokenKind) -> Void
    var onUndo: () -> Void
    var onClear: () -> Void
    var onShare: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 16) {
                Picker("Tool", selection: $tool) {
                    ForEach(DrawTool.allCases) { tool in
                        Label(tool.rawValue, systemImage: tool.systemImage).tag(tool)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 180)

                HStack(spacing: 6) {
                    ForEach(drawColors, id: \.self) { swatch in
                        Circle()
                            .fill(swatch)
                            .frame(width: 24, height: 24)
                            .overlay(Circle().stroke(.white, lineWidth: color == swatch ? 2 : 0))
                            .onTapGesture { color = swatch }
                    }
                }

                Slider(value: $lineWidth, in: 2...12)
                    .frame(maxWidth: 100)

                Spacer()

                Menu {
                    Button("Add Red Player") { onAddToken(.teamA) }
                    Button("Add Blue Player") { onAddToken(.teamB) }
                    Button("Add Ball") { onAddToken(.ball) }
                } label: {
                    Label("Add", systemImage: "plus.circle")
                }

                Button(action: onUndo) {
                    Image(systemName: "arrow.uturn.backward.circle")
                }

                Button(role: .destructive, action: onClear) {
                    Image(systemName: "trash")
                }

                Button(action: onShare) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            .font(.title3)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}
