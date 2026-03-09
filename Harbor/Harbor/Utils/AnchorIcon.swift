//
//  AnchorIcon.swift
//  Harbor
//

import AppKit

enum AnchorIcon {
    /// Creates a custom anchor icon for the menubar based on the Lucide anchor SVG
    /// Reference: https://lucide.dev/icons/anchor
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

        // Use template color (will be automatically tinted by system)
        NSColor.black.setStroke()

        // Stroke width of 2px (from SVG)
        let lineWidth: CGFloat = 2.0

        // Path 1: Vertical line (M12 22V8) - from bottom to top where circle starts
        let verticalLine = NSBezierPath()
        verticalLine.lineWidth = lineWidth
        verticalLine.lineCapStyle = .round
        verticalLine.lineJoinStyle = .round
        verticalLine.move(to: NSPoint(x: 12, y: 22))
        verticalLine.line(to: NSPoint(x: 12, y: 8))
        verticalLine.stroke()

        // Path 2: Anchor arms (M5 12H2a10 10 0 0 0 20 0h-3)
        // This draws the curved bottom part of the anchor
        let armsPath = NSBezierPath()
        armsPath.lineWidth = lineWidth
        armsPath.lineCapStyle = .round
        armsPath.lineJoinStyle = .round

        // Start at left arm
        armsPath.move(to: NSPoint(x: 5, y: 12))
        armsPath.line(to: NSPoint(x: 2, y: 12))

        // Arc for the anchor bottom (radius 10, center at x:12, y:12)
        // SVG arc: a10 10 0 0 0 20 0
        // This is an arc with radius 10, from current point, going 20 units right
        armsPath.appendArc(
            withCenter: NSPoint(x: 12, y: 12),
            radius: 10,
            startAngle: 180, // Start at left (180 degrees)
            endAngle: 0,     // End at right (0 degrees)
            clockwise: true
        )

        // Right arm
        armsPath.line(to: NSPoint(x: 22, y: 12))
        armsPath.stroke()

        // Path 3: Circle at top (cx="12" cy="5" r="3")
        let circle = NSBezierPath()
        circle.lineWidth = lineWidth
        circle.lineCapStyle = .round
        circle.lineJoinStyle = .round
        circle.appendArc(
            withCenter: NSPoint(x: 12, y: 5),
            radius: 3,
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
