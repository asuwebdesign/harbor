//
//  AnchorIcon.swift
//  Harbor
//

import AppKit

enum AnchorIcon {
    /// Creates a custom anchor icon for the menubar based on the Lucide anchor SVG
    static func create(size: CGSize = CGSize(width: 18, height: 18)) -> NSImage {
        let image = NSImage(size: size)

        image.lockFocus()

        // Scale factor to fit SVG (24x24) into our size
        let scale = min(size.width / 24, size.height / 24)
        let transform = NSAffineTransform()
        transform.scale(by: scale)

        NSGraphicsContext.current?.saveGraphicsState()
        transform.concat()

        // Use template color (black, will be automatically tinted by system)
        NSColor.black.setStroke()

        let path = NSBezierPath()
        path.lineWidth = 2.0
        path.lineCapStyle = .round
        path.lineJoinStyle = .round

        // Path 1: Vertical line (M12 6v16)
        path.move(to: NSPoint(x: 12, y: 6))
        path.line(to: NSPoint(x: 12, y: 22))

        // Path 2: Anchor curve (m19 13 2-1a9 9 0 0 1-18 0l2 1)
        // This is a complex curve - we'll draw the anchor arms
        path.move(to: NSPoint(x: 19, y: 13))
        path.line(to: NSPoint(x: 21, y: 12))

        // Left curve (arc)
        let centerY: CGFloat = 12
        path.appendArc(
            withCenter: NSPoint(x: 12, y: centerY),
            radius: 9,
            startAngle: 0,
            endAngle: 180,
            clockwise: true
        )

        path.line(to: NSPoint(x: 5, y: 13))

        // Path 3: Horizontal crossbar (M9 11h6)
        path.move(to: NSPoint(x: 9, y: 11))
        path.line(to: NSPoint(x: 15, y: 11))

        // Circle at top (cx="12" cy="4" r="2")
        path.move(to: NSPoint(x: 14, y: 4))
        path.appendArc(
            withCenter: NSPoint(x: 12, y: 4),
            radius: 2,
            startAngle: 0,
            endAngle: 360
        )

        path.stroke()

        NSGraphicsContext.current?.restoreGraphicsState()

        image.unlockFocus()

        // Set as template so it adapts to light/dark mode
        image.isTemplate = true

        return image
    }
}
