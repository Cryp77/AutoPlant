import AppKit
import CoreImage
import UniformTypeIdentifiers

enum Tool: Int, CaseIterable {
    case arrow, rect, highlight, text, step, blur, crop

    var symbol: String {
        switch self {
        case .arrow: return "arrow.up.right"
        case .rect: return "rectangle"
        case .highlight: return "highlighter"
        case .text: return "textformat"
        case .step: return "1.circle"
        case .blur: return "square.grid.3x3.fill"
        case .crop: return "crop"
        }
    }

    var name: String {
        switch self {
        case .arrow: return "Arrow (A)"
        case .rect: return "Box (R)"
        case .highlight: return "Highlight (H)"
        case .text: return "Text (T)"
        case .step: return "Step number (N)"
        case .blur: return "Pixelate (B)"
        case .crop: return "Crop (C)"
        }
    }

    static let keys: [String: Tool] = ["a": .arrow, "r": .rect, "h": .highlight, "t": .text, "n": .step, "b": .blur, "c": .crop]
}

struct Annotation {
    var tool: Tool
    var start: CGPoint
    var end: CGPoint
    var color: NSColor
    var text = ""

    var rect: CGRect {
        CGRect(x: min(start.x, end.x), y: min(start.y, end.y),
               width: abs(end.x - start.x), height: abs(end.y - start.y))
    }
}

// MARK: - Canvas

/// Coordinates are in points, top-left origin. `scale` is pixels per point of the base image.
final class CanvasView: NSView {
    private(set) var base: CGImage
    let scale: CGFloat
    private var annotations: [Annotation] = []
    private var drafting: Annotation?
    private var history: [(CGImage, [Annotation])] = []
    private var textField: NSTextField?
    private let ciContext = CIContext()
    private let textFont = NSFont.boldSystemFont(ofSize: 22)

    var tool: Tool = .arrow { didSet { commitText(); window?.invalidateCursorRects(for: self) } }
    var color: NSColor = .systemRed
    var onToolKey: ((Tool) -> Void)?

    var pointSize: CGSize { CGSize(width: CGFloat(base.width) / scale, height: CGFloat(base.height) / scale) }

    init(image: CGImage, scale: CGFloat) {
        base = image
        self.scale = scale
        super.init(frame: CGRect(x: 0, y: 0, width: CGFloat(image.width) / scale, height: CGFloat(image.height) / scale))
    }

    required init?(coder: NSCoder) { fatalError() }

    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: tool == .text ? .iBeam : .crosshair)
    }

    // MARK: Drawing

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        render(in: ctx, includeDraft: true)
    }

    private func render(in ctx: CGContext, includeDraft: Bool) {
        drawImage(base, in: CGRect(origin: .zero, size: pointSize), ctx: ctx)
        for a in annotations { draw(a, ctx: ctx) }
        if includeDraft, let d = drafting { draw(d, ctx: ctx) }
    }

    /// CGContext.draw assumes a bottom-left origin, so flip locally.
    private func drawImage(_ img: CGImage, in r: CGRect, ctx: CGContext) {
        ctx.saveGState()
        ctx.translateBy(x: 0, y: r.minY + r.maxY)
        ctx.scaleBy(x: 1, y: -1)
        ctx.draw(img, in: r)
        ctx.restoreGState()
    }

    private func draw(_ a: Annotation, ctx: CGContext) {
        ctx.saveGState()
        defer { ctx.restoreGState() }
        ctx.setStrokeColor(a.color.cgColor)
        ctx.setFillColor(a.color.cgColor)
        ctx.setLineWidth(4)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)

        switch a.tool {
        case .arrow:
            let s = a.start, e = a.end
            let angle = atan2(e.y - s.y, e.x - s.x)
            let head: CGFloat = 20
            ctx.move(to: s)
            ctx.addLine(to: CGPoint(x: e.x - head * 0.7 * cos(angle), y: e.y - head * 0.7 * sin(angle)))
            ctx.strokePath()
            ctx.move(to: e)
            ctx.addLine(to: CGPoint(x: e.x - head * cos(angle - .pi / 7), y: e.y - head * sin(angle - .pi / 7)))
            ctx.addLine(to: CGPoint(x: e.x - head * cos(angle + .pi / 7), y: e.y - head * sin(angle + .pi / 7)))
            ctx.closePath()
            ctx.fillPath()

        case .rect:
            ctx.stroke(a.rect)

        case .highlight:
            ctx.setFillColor(a.color.withAlphaComponent(0.35).cgColor)
            ctx.fill(a.rect)

        case .text:
            let shadow = NSShadow()
            shadow.shadowColor = NSColor.black.withAlphaComponent(0.5)
            shadow.shadowBlurRadius = 2
            NSAttributedString(string: a.text, attributes: [.font: textFont, .foregroundColor: a.color, .shadow: shadow])
                .draw(at: a.start)

        case .step:
            let r: CGFloat = 16
            ctx.fillEllipse(in: CGRect(x: a.start.x - r, y: a.start.y - r, width: r * 2, height: r * 2))
            let label = NSAttributedString(string: a.text, attributes: [
                .font: NSFont.boldSystemFont(ofSize: 17), .foregroundColor: NSColor.white,
            ])
            let size = label.size()
            label.draw(at: CGPoint(x: a.start.x - size.width / 2, y: a.start.y - size.height / 2))

        case .blur:
            let r = a.rect.intersection(CGRect(origin: .zero, size: pointSize))
            if let px = pixelated(r) { drawImage(px, in: r, ctx: ctx) }

        case .crop:
            ctx.setLineWidth(1.5)
            ctx.setStrokeColor(NSColor.white.cgColor)
            ctx.setLineDash(phase: 0, lengths: [6, 4])
            ctx.setShadow(offset: .zero, blur: 2, color: NSColor.black.cgColor)
            ctx.stroke(a.rect)
        }
    }

    private func pixelated(_ r: CGRect) -> CGImage? {
        let px = CGRect(x: r.minX * scale, y: r.minY * scale, width: r.width * scale, height: r.height * scale).integral
        guard px.width > 1, px.height > 1, let crop = base.cropping(to: px) else { return nil }
        let input = CIImage(cgImage: crop)
        let output = input.clampedToExtent()
            .applyingFilter("CIPixellate", parameters: [kCIInputScaleKey: 10 * scale])
            .cropped(to: input.extent)
        return ciContext.createCGImage(output, from: input.extent)
    }

    /// Full-resolution image with annotations burned in.
    func flattened() -> CGImage? {
        commitText()
        guard let ctx = CGContext(data: nil, width: base.width, height: base.height, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        ctx.translateBy(x: 0, y: CGFloat(base.height))
        ctx.scaleBy(x: scale, y: -scale)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: true)
        render(in: ctx, includeDraft: false)
        NSGraphicsContext.restoreGraphicsState()
        return ctx.makeImage()
    }

    // MARK: Mouse

    private func point(_ e: NSEvent) -> CGPoint {
        let p = convert(e.locationInWindow, from: nil)
        return CGPoint(x: min(max(p.x, 0), bounds.width), y: min(max(p.y, 0), bounds.height))
    }

    override func mouseDown(with e: NSEvent) {
        commitText()
        let p = point(e)
        switch tool {
        case .text:
            beginText(at: p)
        case .step:
            let n = annotations.filter { $0.tool == .step }.count + 1
            pushHistory()
            annotations.append(Annotation(tool: .step, start: p, end: p, color: color, text: "\(n)"))
            needsDisplay = true
        default:
            drafting = Annotation(tool: tool, start: p, end: p, color: color)
        }
    }

    override func mouseDragged(with e: NSEvent) {
        guard drafting != nil else { return }
        drafting?.end = point(e)
        needsDisplay = true
    }

    override func mouseUp(with e: NSEvent) {
        guard let d = drafting else { return }
        drafting = nil
        needsDisplay = true
        guard hypot(d.end.x - d.start.x, d.end.y - d.start.y) > 4 else { return }
        if d.tool == .crop {
            crop(to: d.rect)
        } else {
            pushHistory()
            annotations.append(d)
        }
    }

    private func crop(to r: CGRect) {
        let px = CGRect(x: r.minX * scale, y: r.minY * scale, width: r.width * scale, height: r.height * scale).integral
        guard let flat = flattened(), let cropped = flat.cropping(to: px) else { return }
        pushHistory()
        base = cropped
        annotations = []
        setFrameSize(pointSize)
        needsDisplay = true
    }

    override func keyDown(with e: NSEvent) {
        if e.modifierFlags.intersection([.command, .control, .option]).isEmpty,
           let t = Tool.keys[e.charactersIgnoringModifiers?.lowercased() ?? ""] {
            onToolKey?(t)
        } else {
            super.keyDown(with: e)
        }
    }

    // MARK: Text

    private func beginText(at p: CGPoint) {
        let tf = NSTextField(frame: CGRect(x: p.x, y: p.y, width: 260, height: 30))
        tf.font = textFont
        tf.textColor = color
        tf.backgroundColor = NSColor.white.withAlphaComponent(0.85)
        tf.placeholderString = "Type, then Return"
        tf.target = self
        tf.action = #selector(textDone)
        addSubview(tf)
        window?.makeFirstResponder(tf)
        textField = tf
    }

    @objc private func textDone() { commitText() }

    func commitText() {
        guard let tf = textField else { return }
        textField = nil // set first: removing the field fires its action again
        let text = tf.stringValue
        tf.removeFromSuperview()
        if !text.isEmpty {
            pushHistory()
            annotations.append(Annotation(tool: .text, start: tf.frame.origin, end: tf.frame.origin,
                                          color: tf.textColor ?? color, text: text))
        }
        window?.makeFirstResponder(self)
        needsDisplay = true
    }

    // MARK: Undo

    private func pushHistory() { history.append((base, annotations)) }

    func undo() {
        if let tf = textField {
            textField = nil
            tf.removeFromSuperview()
            window?.makeFirstResponder(self)
            return
        }
        guard let last = history.popLast() else { NSSound.beep(); return }
        base = last.0
        annotations = last.1
        setFrameSize(pointSize)
        needsDisplay = true
    }
}

// MARK: - Window

final class EditorWindow: NSWindow {
    private let canvas: CanvasView
    private let toolPicker = NSSegmentedControl()

    init(image: CGImage, scale: CGFloat) {
        canvas = CanvasView(image: image, scale: scale)

        let screen = NSScreen.main?.visibleFrame.size ?? CGSize(width: 1440, height: 900)
        let size = CGSize(width: min(max(canvas.pointSize.width, 720), screen.width * 0.9),
                          height: min(max(canvas.pointSize.height + 48, 360), screen.height * 0.9))
        super.init(contentRect: CGRect(origin: .zero, size: size),
                   styleMask: [.titled, .closable, .miniaturizable, .resizable],
                   backing: .buffered, defer: false)
        title = "Snapper"
        isReleasedWhenClosed = false

        toolPicker.trackingMode = .selectOne
        toolPicker.segmentCount = Tool.allCases.count
        for t in Tool.allCases {
            toolPicker.setImage(NSImage(systemSymbolName: t.symbol, accessibilityDescription: t.name), forSegment: t.rawValue)
            toolPicker.setToolTip(t.name, forSegment: t.rawValue)
        }
        toolPicker.selectedSegment = Tool.arrow.rawValue
        toolPicker.target = self
        toolPicker.action = #selector(toolChanged)
        canvas.onToolKey = { [weak self] t in self?.select(t) }

        let well = NSColorWell()
        well.color = canvas.color
        well.target = self
        well.action = #selector(colorChanged(_:))
        well.widthAnchor.constraint(equalToConstant: 44).isActive = true

        let toolbar = NSStackView(views: [
            toolPicker, well,
            NSButton(title: "Undo", target: self, action: #selector(undo)),
            NSButton(title: "Copy", target: self, action: #selector(copyImage)),
            NSButton(title: "Save…", target: self, action: #selector(save)),
        ])
        toolbar.spacing = 10
        toolbar.edgeInsets = NSEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)

        let scroll = NSScrollView()
        scroll.documentView = canvas
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = true
        scroll.backgroundColor = .underPageBackgroundColor

        let root = NSView()
        for v in [toolbar, scroll] as [NSView] {
            v.translatesAutoresizingMaskIntoConstraints = false
            root.addSubview(v)
        }
        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: root.topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            scroll.topAnchor.constraint(equalTo: toolbar.bottomAnchor),
            scroll.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: root.bottomAnchor),
        ])
        contentView = root
        center()
        makeFirstResponder(canvas)
    }

    // ⌘C / ⌘S / ⌘Z / ⌘W without needing a menu bar (Snapper is a menu-bar-only app).
    override func performKeyEquivalent(with e: NSEvent) -> Bool {
        let editingText = firstResponder is NSTextView
        if e.modifierFlags.intersection([.command, .control, .option]) == .command, !editingText {
            switch e.charactersIgnoringModifiers {
            case "c": copyImage(); return true
            case "s": save(); return true
            case "z": undo(); return true
            case "w": close(); return true
            default: break
            }
        }
        return super.performKeyEquivalent(with: e)
    }

    private func select(_ t: Tool) {
        toolPicker.selectedSegment = t.rawValue
        canvas.tool = t
    }

    @objc private func toolChanged() {
        canvas.tool = Tool(rawValue: toolPicker.selectedSegment) ?? .arrow
        makeFirstResponder(canvas)
    }

    @objc private func colorChanged(_ well: NSColorWell) { canvas.color = well.color }

    @objc private func undo() { canvas.undo() }

    @objc private func copyImage() {
        guard let img = canvas.flattened() else { return }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.writeObjects([NSImage(cgImage: img, size: canvas.pointSize)])
        title = "Snapper — copied to clipboard"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in self?.title = "Snapper" }
    }

    @objc private func save() {
        guard let img = canvas.flattened() else { return }
        let rep = NSBitmapImageRep(cgImage: img)
        rep.size = canvas.pointSize // keeps Retina DPI metadata
        guard let png = rep.representation(using: .png, properties: [:]) else { return }

        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "Snapper \(f.string(from: Date())).png"
        panel.beginSheetModal(for: self) { response in
            guard response == .OK, let url = panel.url else { return }
            do { try png.write(to: url) } catch { NSAlert(error: error).runModal() }
        }
    }
}
