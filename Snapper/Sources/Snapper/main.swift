import AppKit
import Carbon
import UniformTypeIdentifiers

/// Global hotkey via Carbon — still the only public API for system-wide shortcuts.
final class HotKey {
    static var handler: (() -> Void)?
    private var ref: EventHotKeyRef?

    init(keyCode: UInt32, modifiers: UInt32, handler: @escaping () -> Void) {
        HotKey.handler = handler
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, _ in
            HotKey.handler?()
            return noErr
        }, 1, &spec, nil, nil)
        let id = EventHotKeyID(signature: OSType(0x534E_4150), id: 1) // 'SNAP'
        RegisterEventHotKey(keyCode, modifiers, id, GetApplicationEventTarget(), 0, &ref)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var statusItem: NSStatusItem!
    private var hotKey: HotKey?
    private var editors: [EditorWindow] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(systemSymbolName: "camera.viewfinder", accessibilityDescription: "Snapper")

        let menu = NSMenu()
        let region = NSMenuItem(title: "Capture Region / Window", action: #selector(captureRegion), keyEquivalent: "2")
        region.keyEquivalentModifierMask = [.command, .shift]
        menu.addItem(region)
        menu.addItem(NSMenuItem(title: "Capture Full Screen", action: #selector(captureFullScreen), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Open Image…", action: #selector(openImage), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Snapper", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        menu.items.forEach { if $0.action != #selector(NSApplication.terminate(_:)) { $0.target = self } }
        statusItem.menu = menu

        // ⌘⇧2 — kVK_ANSI_2 is 0x13
        hotKey = HotKey(keyCode: 0x13, modifiers: UInt32(cmdKey | shiftKey)) { [weak self] in
            self?.captureRegion()
        }
    }

    // MARK: Capture

    /// Space bar toggles window mode, Esc cancels — that's screencapture's own UI.
    @objc func captureRegion() { capture(["-i", "-x"]) }
    @objc func captureFullScreen() { capture(["-x"]) }

    private func capture(_ args: [String]) {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("snapper-\(UUID().uuidString).png")
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        p.arguments = args + [url.path]
        p.terminationHandler = { _ in
            DispatchQueue.main.async {
                self.openEditor(url: url)
                try? FileManager.default.removeItem(at: url)
            }
        }
        try? p.run()
    }

    @objc func openImage() {
        NSApp.activate(ignoringOtherApps: true)
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        if panel.runModal() == .OK, let url = panel.url { openEditor(url: url) }
    }

    private func openEditor(url: URL) {
        // Cancelled capture leaves no file; that's fine, just bail.
        guard let data = try? Data(contentsOf: url),
              let src = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(src, 0, nil) else { return }
        let props = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [CFString: Any]
        let dpi = (props?[kCGImagePropertyDPIWidth] as? NSNumber)?.doubleValue ?? 72
        let scale = max(1, CGFloat(dpi) / 72) // Retina screenshots are 144 dpi

        let editor = EditorWindow(image: image, scale: scale)
        editor.delegate = self
        editors.append(editor)
        NSApp.activate(ignoringOtherApps: true)
        editor.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        editors.removeAll { $0 === notification.object as? EditorWindow }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
