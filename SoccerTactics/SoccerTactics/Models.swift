import SwiftUI

enum DrawTool: String, CaseIterable, Identifiable {
    case pen = "Pen"
    case arrow = "Arrow"

    var id: String { rawValue }
    var systemImage: String {
        switch self {
        case .pen: return "pencil"
        case .arrow: return "arrow.up.right"
        }
    }
}

enum TokenKind {
    case teamA
    case teamB
    case ball

    var color: Color {
        switch self {
        case .teamA: return .red
        case .teamB: return .blue
        case .ball: return .white
        }
    }

    var size: CGFloat {
        self == .ball ? 22 : 34
    }
}

extension TokenKind: Equatable {}

struct Stroke: Identifiable {
    let id = UUID()
    var points: [CGPoint]
    var color: Color
    var lineWidth: CGFloat
    var isArrow: Bool
}

struct PlayerToken: Identifiable {
    let id = UUID()
    var kind: TokenKind
    var label: String
    var position: CGPoint
}

let drawColors: [Color] = [.white, .yellow, .orange, .red, .blue, .black]
