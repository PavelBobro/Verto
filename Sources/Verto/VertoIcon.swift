import AppKit

/// The menu bar mark: the app icon in miniature — a solid plate with the V cut clean
/// through it. Drawn rather than taken from SF Symbols, and template mode lets macOS
/// recolour it, so one asset covers every wallpaper and both themes.
enum VertoIcon {

    /// K — one solid shape with the letter cut clean through it. Filled marks hold up
    /// better than outlines at menu bar size, and a knocked-out letter cannot merge
    /// with the frame around it.
    static func menuBar(size: CGFloat = 20) -> NSImage {
        let scale = size / 20

        let image = NSImage(size: NSSize(width: size, height: size), flipped: true) { _ in
            func point(_ x: CGFloat, _ y: CGFloat) -> NSPoint {
                NSPoint(x: x * scale, y: y * scale)
            }

            let path = NSBezierPath()
            path.appendRoundedRect(NSRect(x: 1.1 * scale, y: 1.1 * scale,
                                          width: 17.8 * scale, height: 17.8 * scale),
                                   xRadius: 4.8 * scale, yRadius: 4.8 * scale)

            // The V as a solid letterform, subtracted by the even-odd rule.
            path.move(to: point(4.7, 5.3))
            path.line(to: point(7.2, 5.3))
            path.line(to: point(10.0, 12.2))
            path.line(to: point(12.8, 5.3))
            path.line(to: point(15.3, 5.3))
            path.line(to: point(11.5, 14.7))
            path.line(to: point(8.5, 14.7))
            path.close()

            path.windingRule = .evenOdd
            NSColor.black.setFill()
            path.fill()

            return true
        }

        image.isTemplate = true
        return image
    }
}
