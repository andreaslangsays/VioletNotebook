import SwiftUI

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var totalHeight: CGFloat = 0
        var currentLineWidth: CGFloat = 0
        var currentLineHeight: CGFloat = 0
        var maxLineWidth: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let neededWidth = size.width + (currentLineWidth > 0 ? spacing : 0)
            if currentLineWidth + neededWidth > width && currentLineWidth > 0 {
                // Wrap to next line
                totalHeight += currentLineHeight + lineSpacing
                maxLineWidth = max(maxLineWidth, currentLineWidth)
                currentLineWidth = 0
                currentLineHeight = 0
            }
            if currentLineWidth > 0 {
                currentLineWidth += spacing
            }
            currentLineWidth += size.width
            currentLineHeight = max(currentLineHeight, size.height)
        }
        totalHeight += currentLineHeight
        maxLineWidth = max(maxLineWidth, currentLineWidth)
        
        let resultWidth = proposal.width ?? maxLineWidth
        return CGSize(width: resultWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var currentLineHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                // Wrap to next line
                x = bounds.minX
                y += currentLineHeight + lineSpacing
                currentLineHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            currentLineHeight = max(currentLineHeight, size.height)
            x += size.width + spacing
        }
    }
}
