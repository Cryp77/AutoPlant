# Snapper

A small Snagit-style screenshot tool for macOS (13+). It lives in the menu bar.

- **⌘⇧2**: capture a region. Press **Space** to switch to window capture, **Esc** to cancel.
- Menu bar icon → Capture Full Screen / Open Image…
- Editor tools (shortcut key in brackets): Arrow (A), Box (R), Highlight (H), Text (T),
  numbered Steps (N), Pixelate (B), Crop (C). Pick a colour with the colour well.
- **⌘Z** undo · **⌘C** copy to clipboard · **⌘S** save PNG · **⌘W** close

## Build

Needs the Xcode Command Line Tools (`xcode-select --install`). The full Xcode app isn't required.

```bash
cd Snapper
./build.sh
open build/Snapper.app        # or move it to /Applications first
```

The first time you capture, macOS asks for **Screen Recording** permission. Grant it in
System Settings → Privacy & Security → Screen & System Audio Recording, then quit and reopen Snapper.
The app is ad-hoc signed, so macOS may ask for permission again after each rebuild.
