import AppKit

/// Draws the menu-bar glyph: a monochrome mouse that echoes the app icon, with
/// the middle button (scroll wheel) emphasised — the "third button" the app adds.
///
/// Returned as a *template* image, so macOS tints it automatically: black on a
/// light menu bar, white on a dark one, inverting while the menu is open. That's
/// the system-sanctioned way to honour the menu bar's black/white convention.
///
/// The wheel is solid when the gesture is enabled and a hollow outline when it
/// is disabled, mirroring how the app icon highlights the middle button.
enum MenuBarIcon {
    static func image(enabled: Bool) -> NSImage {
        // A touch taller than wide, leaving room for the 1.6pt body stroke.
        let size = NSSize(width: 16, height: 18)
        let image = NSImage(size: size, flipped: false) { _ in
            NSColor.black.set()

            // Mouse body: a vertical capsule outline.
            let body = NSBezierPath(
                roundedRect: NSRect(x: 2.5, y: 1, width: 11, height: 16),
                xRadius: 5.5, yRadius: 5.5
            )
            body.lineWidth = 1.6
            body.stroke()

            // Middle button / scroll wheel, upper-centre of the body.
            let wheel = NSBezierPath(
                roundedRect: NSRect(x: 6.6, y: 9.7, width: 2.8, height: 5.3),
                xRadius: 1.4, yRadius: 1.4
            )
            if enabled {
                wheel.fill()
            } else {
                wheel.lineWidth = 1.1
                wheel.stroke()
            }
            return true
        }
        image.isTemplate = true
        return image
    }
}
