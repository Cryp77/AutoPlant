# Soccer Tactics

A SwiftUI iPhone/iPad app: a whiteboard over a soccer pitch for drawing up plays.

## Open in Xcode

Double-click `SoccerTactics.xcodeproj` (requires Xcode 15+, targets iOS 16+).
Pick your own team/signing under the target's Signing & Capabilities tab before
running on a device — a Simulator run needs no signing changes.

## Features

- Full-field pitch (halfway line, center circle, penalty/goal boxes, corner arcs)
- Freehand pen and straight-arrow drawing tools, with color and thickness controls
- Draggable red/blue player tokens and a ball; double-tap a token to remove it
- Undo last stroke / clear the whole board
- Export the current board as an image via the share sheet

## Possible next steps (not built yet)

- Persist and reload named plays (currently everything resets when the app closes)
- Multi-page playbooks / animation between formations
