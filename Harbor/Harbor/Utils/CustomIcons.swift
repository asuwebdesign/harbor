//
//  CustomIcons.swift
//  Harbor
//

import SwiftUI

/// Custom folder icon matching the provided SVG design
struct FolderIcon: View {
    var body: some View {
        Canvas { context, size in
            let scale = min(size.width / 16, size.height / 16)

            context.scaleBy(x: scale, y: scale)

            // Path 1: Top folder flap
            var path1 = Path()
            path1.move(to: CGPoint(x: 3.5, y: 2))
            path1.addCurve(
                to: CGPoint(x: 2, y: 3.5),
                control1: CGPoint(x: 2.672, y: 2),
                control2: CGPoint(x: 2, y: 2.672)
            )
            path1.addLine(to: CGPoint(x: 2, y: 6.901))
            path1.addCurve(
                to: CGPoint(x: 3.5, y: 6.5),
                control1: CGPoint(x: 2.441, y: 6.646),
                control2: CGPoint(x: 2.954, y: 6.5)
            )
            path1.addLine(to: CGPoint(x: 12.5, y: 6.5))
            path1.addCurve(
                to: CGPoint(x: 14, y: 5.5),
                control1: CGPoint(x: 13.328, y: 6.5),
                control2: CGPoint(x: 14, y: 5.828)
            )
            path1.addLine(to: CGPoint(x: 14, y: 5.5))
            path1.addLine(to: CGPoint(x: 14, y: 5.5))
            path1.addCurve(
                to: CGPoint(x: 12.5, y: 4),
                control1: CGPoint(x: 14, y: 4.672),
                control2: CGPoint(x: 13.328, y: 4)
            )
            path1.addLine(to: CGPoint(x: 9.621, y: 4))
            path1.addCurve(
                to: CGPoint(x: 8.561, y: 3.56),
                control1: CGPoint(x: 9.223, y: 4),
                control2: CGPoint(x: 8.842, y: 3.841)
            )
            path1.addLine(to: CGPoint(x: 7.439, y: 2.44))
            path1.addCurve(
                to: CGPoint(x: 6.379, y: 2),
                control1: CGPoint(x: 7.158, y: 2.159),
                control2: CGPoint(x: 6.777, y: 2)
            )
            path1.addLine(to: CGPoint(x: 3.5, y: 2))
            path1.closeSubpath()

            context.fill(path1, with: .color(.primary))

            // Path 2: Bottom folder body
            var path2 = Path()
            path2.move(to: CGPoint(x: 2, y: 9.5))
            path2.addLine(to: CGPoint(x: 2, y: 12.5))
            path2.addCurve(
                to: CGPoint(x: 3.5, y: 14),
                control1: CGPoint(x: 2, y: 13.328),
                control2: CGPoint(x: 2.672, y: 14)
            )
            path2.addLine(to: CGPoint(x: 12.5, y: 14))
            path2.addCurve(
                to: CGPoint(x: 14, y: 12.5),
                control1: CGPoint(x: 13.328, y: 14),
                control2: CGPoint(x: 14, y: 13.328)
            )
            path2.addLine(to: CGPoint(x: 14, y: 9.5))
            path2.addCurve(
                to: CGPoint(x: 12.5, y: 8),
                control1: CGPoint(x: 14, y: 8.672),
                control2: CGPoint(x: 13.328, y: 8)
            )
            path2.addLine(to: CGPoint(x: 3.5, y: 8))
            path2.addCurve(
                to: CGPoint(x: 2, y: 9.5),
                control1: CGPoint(x: 2.672, y: 8),
                control2: CGPoint(x: 2, y: 8.672)
            )
            path2.closeSubpath()

            context.fill(path2, with: .color(.primary))
        }
        .frame(width: 16, height: 16)
    }
}

/// Custom stop icon matching the provided SVG design (circle with square inside)
struct StopCircleIcon: View {
    var body: some View {
        Canvas { context, size in
            let scale = min(size.width / 16, size.height / 16)

            context.scaleBy(x: scale, y: scale)

            // Outer circle
            let circlePath = Path(ellipseIn: CGRect(x: 1, y: 1, width: 14, height: 14))
            context.fill(circlePath, with: .color(.primary))

            // Inner square (inset)
            var squarePath = Path()
            squarePath.move(to: CGPoint(x: 6.5, y: 5.5))
            squarePath.addCurve(
                to: CGPoint(x: 5.5, y: 6.5),
                control1: CGPoint(x: 5.948, y: 5.5),
                control2: CGPoint(x: 5.5, y: 5.948)
            )
            squarePath.addLine(to: CGPoint(x: 5.5, y: 9.5))
            squarePath.addCurve(
                to: CGPoint(x: 6.5, y: 10.5),
                control1: CGPoint(x: 5.5, y: 10.052),
                control2: CGPoint(x: 5.948, y: 10.5)
            )
            squarePath.addLine(to: CGPoint(x: 9.5, y: 10.5))
            squarePath.addCurve(
                to: CGPoint(x: 10.5, y: 9.5),
                control1: CGPoint(x: 10.052, y: 10.5),
                control2: CGPoint(x: 10.5, y: 10.052)
            )
            squarePath.addLine(to: CGPoint(x: 10.5, y: 6.5))
            squarePath.addCurve(
                to: CGPoint(x: 9.5, y: 5.5),
                control1: CGPoint(x: 10.5, y: 5.948),
                control2: CGPoint(x: 10.052, y: 5.5)
            )
            squarePath.addLine(to: CGPoint(x: 6.5, y: 5.5))
            squarePath.closeSubpath()

            context.fill(squarePath, with: .color(Color(white: 0, opacity: 0)))
            context.blendMode = .destinationOut
            context.fill(squarePath, with: .color(.primary))
        }
        .frame(width: 16, height: 16)
    }
}
