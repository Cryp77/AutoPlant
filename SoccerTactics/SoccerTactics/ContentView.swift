import SwiftUI

struct ContentView: View {
    @State private var strokes: [Stroke] = []
    @State private var tokens: [PlayerToken] = []
    @State private var tool: DrawTool = .pen
    @State private var color: Color = .white
    @State private var lineWidth: CGFloat = 5
    @State private var showClearConfirm = false
    @State private var shareImage: IdentifiableImage?
    @State private var boardSize: CGSize = CGSize(width: 700, height: 440)

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                boardView
                ToolbarView(
                    tool: $tool,
                    color: $color,
                    lineWidth: $lineWidth,
                    onAddToken: addToken,
                    onUndo: { if !strokes.isEmpty { strokes.removeLast() } },
                    onClear: { showClearConfirm = true },
                    onShare: exportImage
                )
            }
            .navigationTitle("Soccer Tactics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .confirmationDialog("Clear the whole board?", isPresented: $showClearConfirm, titleVisibility: .visible) {
                Button("Clear Everything", role: .destructive) {
                    strokes.removeAll()
                    tokens.removeAll()
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(item: $shareImage) { wrapper in
                ShareSheet(activityItems: [wrapper.image])
            }
        }
    }

    private var boardView: some View {
        GeometryReader { geo in
            ZStack {
                SoccerFieldView()
                WhiteboardView(
                    strokes: $strokes,
                    tool: tool,
                    color: color,
                    lineWidth: lineWidth,
                    isDrawingEnabled: true
                )
                ForEach($tokens) { $token in
                    TokenView(token: $token) {
                        tokens.removeAll { $0.id == token.id }
                    }
                }
            }
            .onAppear { boardSize = geo.size }
            .onChange(of: geo.size) { boardSize = $0 }
        }
        .padding(8)
        .background(Color.black)
    }

    private func addToken(_ kind: TokenKind) {
        let label: String
        switch kind {
        case .ball:
            label = ""
        case .teamA:
            label = "\(tokens.filter { $0.kind == .teamA }.count + 1)"
        case .teamB:
            label = "\(tokens.filter { $0.kind == .teamB }.count + 1)"
        }
        let center = CGPoint(x: boardSize.width / 2, y: boardSize.height / 2)
        tokens.append(PlayerToken(kind: kind, label: label, position: center))
    }

    @MainActor
    private func exportImage() {
        let renderer = ImageRenderer(content: boardSnapshot)
        renderer.scale = UIScreen.main.scale
        if let uiImage = renderer.uiImage {
            shareImage = IdentifiableImage(image: uiImage)
        }
    }

    private var boardSnapshot: some View {
        ZStack {
            SoccerFieldView()
            WhiteboardView(strokes: .constant(strokes), tool: tool, color: color, lineWidth: lineWidth, isDrawingEnabled: false)
            ForEach(tokens) { token in
                ZStack {
                    Circle().fill(token.kind.color).overlay(Circle().stroke(.white, lineWidth: 2)).frame(width: token.kind.size, height: token.kind.size)
                    if token.kind != .ball {
                        Text(token.label).font(.system(size: 13, weight: .bold)).foregroundStyle(.white)
                    }
                }
                .position(token.position)
            }
        }
        .frame(width: boardSize.width, height: boardSize.height)
    }
}

private struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ContentView()
}
