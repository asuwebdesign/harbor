//
//  AnchorIcon.swift
//  Harbor
//

import AppKit

enum AnchorIcon {
    /// Creates a custom anchor icon for the menubar based on the Lucide anchor SVG
    /// Reference: https://lucide.dev/icons/anchor
    /// SVG viewBox: 0 0 24 24
    static func create(size: CGSize = CGSize(width: 18, height: 18)) -> NSImage {
        let image = NSImage(size: size)

        image.lockFocus()

        // Scale factor to fit SVG (24x24) into our size
        let scale = min(size.width / 24, size.height / 24)
        let offsetX = (size.width - 24 * scale) / 2
        let offsetY = (size.height - 24 * scale) / 2

        let transform = NSAffineTransform()
        transform.translateX(by: offsetX, yBy: offsetY)
        transform.scale(by: scale)

        NSGraphicsContext.current?.saveGraphicsState()
        transform.concat()

        // Flip Y-axis to match SVG coordinate system (Y grows downward in SVG, upward in AppKit)
        let flipTransform = NSAffineTransform()
        flipTransform.translateX(by: 0, yBy: 24)
        flipTransform.scaleX(by: 1, yBy: -1)
        flipTransform.concat()

        // Use template color (will be automatically tinted by system)
        NSColor.black.setStroke()

        // Stroke width of 2px (from SVG)
        let lineWidth: CGFloat = 2.0

        // Path 1: Vertical line (M12 6v16) - from (12,6) to (12,22)
        let verticalLine = NSBezierPath()
        verticalLine.lineWidth = lineWidth
        verticalLine.lineCapStyle = .round
        verticalLine.lineJoinStyle = .round
        verticalLine.move(to: NSPoint(x: 12, y: 6))
        verticalLine.line(to: NSPoint(x: 12, y: 22))
        verticalLine.stroke()

        // Path 2: Anchor arms (m19 13 l2-1 a9 9 0 0 1-18 0 l2 1)
        let armsPath = NSBezierPath()
        armsPath.lineWidth = lineWidth
        armsPath.lineCapStyle = .round
        armsPath.lineJoinStyle = .round

        // m19 13 - move to (19, 13)
        armsPath.move(to: NSPoint(x: 19, y: 13))
        // l2-1 - line relative: +2 x, -1 y → (21, 12)
        armsPath.line(to: NSPoint(x: 21, y: 12))

        // a9 9 0 0 1-18 0 - arc with radius 9, sweep flag 1, relative end: -18 x, 0 y
        // From (21, 12) to (3, 12)
        armsPath.appendArc(
            withCenter: NSPoint(x: 12, y: 12),
            radius: 9,
            startAngle: 0,
            endAngle: 180,
            clockwise: false
        )

        // l2 1 - line relative: +2 x, +1 y → (5, 13)
        armsPath.line(to: NSPoint(x: 5, y: 13))
        armsPath.stroke()

        // Path 3: Horizontal crossbar (M9 11h6) - from (9,11) to (15,11)
        let crossbar = NSBezierPath()
        crossbar.lineWidth = lineWidth
        crossbar.lineCapStyle = .round
        crossbar.lineJoinStyle = .round
        crossbar.move(to: NSPoint(x: 9, y: 11))
        crossbar.line(to: NSPoint(x: 15, y: 11))
        crossbar.stroke()

        // Path 4: Circle at top (cx="12" cy="4" r="2")
        let circle = NSBezierPath()
        circle.lineWidth = lineWidth
        circle.lineCapStyle = .round
        circle.lineJoinStyle = .round
        circle.appendArc(
            withCenter: NSPoint(x: 12, y: 4),
            radius: 2,
            startAngle: 0,
            endAngle: 360,
            clockwise: false
        )
        circle.stroke()

        NSGraphicsContext.current?.restoreGraphicsState()

        image.unlockFocus()

        // Set as template so it adapts to light/dark mode
        image.isTemplate = true

        return image
    }
}
