import AppKit

guard let emoji = CommandLine.arguments.dropFirst().first else {
    fputs("usage: notifire <emoji>\n", stderr)
    exit(1)
}

NSApplication.shared.setActivationPolicy(.prohibited) // Never activate (.accessory still steals focus on launch)

// Frame of the frontmost app's topmost normal (layer 0) window
// kCGWindowBounds is readable without Screen Recording permission
func activeWindowFrame() -> NSRect? {
    guard let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier,
          let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[CFString: Any]],
          let info = list.first(where: { $0[kCGWindowOwnerPID] as? pid_t == pid && $0[kCGWindowLayer] as? Int == 0 }),
          let dict = info[kCGWindowBounds], let r = CGRect(dictionaryRepresentation: dict as! CFDictionary)
    else { return nil }
    // CG coords (top-left origin of primary screen, y down) -> Cocoa coords (bottom-left origin, y up)
    return NSRect(x: r.minX, y: NSScreen.screens[0].frame.height - r.maxY, width: r.width, height: r.height)
}

// Cover the whole screen containing the active window's center; fall back to the main screen
let frame = activeWindowFrame().flatMap { w in NSScreen.screens.first { $0.frame.contains(NSPoint(x: w.midX, y: w.midY)) }?.frame } ?? NSScreen.main!.frame
let win = NSPanel(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
win.isOpaque = false
win.backgroundColor = .clear
win.hasShadow = false // Shadows on transparent windows are recomputed every frame, which is expensive
win.level = .screenSaver
win.ignoresMouseEvents = true
win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
win.contentView!.wantsLayer = true

// Rain the emoji given as the first argument (e.g. notifire ✅)
let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 36)]
let image = NSImage(size: emoji.size(withAttributes: attrs), flipped: false) { _ in emoji.draw(at: .zero, withAttributes: attrs); return true }
    .cgImage(forProposedRect: nil, context: nil, hints: nil)

let gravity: CGFloat = 1800 // Higher = faster rise and fall (the apex is kept at the top edge via speed)

// Derive speed and angle from width/height so the apex hits the top edge (vy = sqrt(2gh))
// and the horizontal center (vx = (w/2) / rise time)
let vy = (2 * gravity * frame.height).squareRoot()
let vx = frame.width / 2 / (vy / gravity)
let speed = hypot(vx, vy)
let tilt = atan2(vx, vy) // Tilt from vertical

// Raycast-style: shoot inward diagonally from both bottom corners
[(CGFloat(0), CGFloat.pi / 2 - tilt), (frame.width, CGFloat.pi / 2 + tilt)].forEach { x, angle in
    let e = CAEmitterLayer()
    e.emitterPosition = .init(x: x, y: 0)
    let c = CAEmitterCell()
    c.contents = image
    c.contentsScale = win.backingScaleFactor // Scale factor of the screen the window is on
    c.birthRate = 120 // 60 particles total = 2 emitters × 0.25s burst × birthRate
    c.lifetime = 3
    c.emissionLongitude = angle
    c.emissionRange = .pi / 8
    c.velocity = speed
    c.velocityRange = speed * 0.25
    c.yAcceleration = -gravity // AppKit's y axis points up
    c.alphaSpeed = -1 / c.lifetime // Fade out linearly over the lifetime
    c.spin = 4
    c.spinRange = 8
    c.scaleRange = 0.5
    e.emitterCells = [c]
    e.beginTime = CACurrentMediaTime()
    win.contentView!.layer!.addSublayer(e)
}
win.orderFrontRegardless()

DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { win.contentView!.layer!.sublayers!.forEach { ($0 as! CAEmitterLayer).birthRate = 0 } } // Short burst
DispatchQueue.main.asyncAfter(deadline: .now() + 3) { exit(0) }
NSApp.run()
