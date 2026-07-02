import UIKit

/// Curated overhead composition inspired by Japanese editorial magazine flatlays
/// (e.g. &Premium, POPEYE object spreads): warm paper tone, asymmetric balance,
/// size hierarchy, restrained rotation, generous negative space.
enum EditorialFlatlayLayout {
    struct ItemStyle {
        let size: CGFloat
        let rotation: CGFloat
        let zIndex: Int
    }

    struct Placement {
        let center: CGPoint
        let style: ItemStyle
    }

    // Warm washi-paper studio backdrop
    static var canvasBackground: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.11, green: 0.105, blue: 0.10, alpha: 1)
                : UIColor(red: 0.972, green: 0.965, blue: 0.948, alpha: 1)
        }
    }

    private static let sizeLadder: [CGFloat] = [215, 165, 138, 192, 122, 172, 148, 128, 205, 142, 158, 132]
    private static let rotationPalette: [CGFloat] = [-2.2, 1.4, -0.9, 1.7, -1.5, 0.7, -1.1, 2.0, -0.4, 1.2, -1.8, 0.5]

    /// Normalized anchor points — asymmetric editorial composition with breathing room
    private static let compositionAnchors: [(x: CGFloat, y: CGFloat)] = [
        (0.30, 0.26),
        (0.70, 0.20),
        (0.50, 0.44),
        (0.22, 0.58),
        (0.76, 0.54),
        (0.40, 0.72),
        (0.62, 0.30),
        (0.16, 0.38),
        (0.84, 0.36),
        (0.54, 0.66),
        (0.34, 0.48),
        (0.68, 0.68),
    ]

    static func itemStyle(at index: Int, total: Int) -> ItemStyle {
        let size = sizeLadder[index % sizeLadder.count]
        let degrees = rotationPalette[index % rotationPalette.count]
        let zIndex = sizeLadder.count - (index % sizeLadder.count)
        return ItemStyle(
            size: size,
            rotation: degrees * .pi / 180,
            zIndex: zIndex
        )
    }

    static func placements(for memories: [Memory], canvasSize: CGSize) -> [UUID: Placement] {
        let sorted = memories.sorted { $0.date > $1.date }
        let total = sorted.count
        guard total > 0 else { return [:] }

        let region = layoutRegion(in: canvasSize)
        var result: [UUID: Placement] = [:]

        for (index, memory) in sorted.enumerated() {
            let anchor = compositionAnchors[index % compositionAnchors.count]
            let style = itemStyle(at: index, total: total)
            let jitter = editorialJitter(for: memory.id)

            let center = CGPoint(
                x: region.minX + region.width * anchor.x + jitter.x,
                y: region.minY + region.height * anchor.y + jitter.y
            )

            result[memory.id] = Placement(center: center, style: style)
        }

        return result
    }

    /// Drop positions across the top — loose editorial row before gravity takes over
    static func gravityDropCenter(for index: Int, total: Int, viewWidth: CGFloat) -> CGPoint {
        let anchor = compositionAnchors[index % compositionAnchors.count]
        let style = itemStyle(at: index, total: total)
        let x = viewWidth * anchor.x
        let y = -(style.size * 0.6 + CGFloat(index + 1) * 36 + 24)
        return CGPoint(x: x, y: y)
    }

    private static func layoutRegion(in canvasSize: CGSize) -> CGRect {
        CGRect(
            x: canvasSize.width * 0.18,
            y: canvasSize.height * 0.14,
            width: canvasSize.width * 0.64,
            height: canvasSize.height * 0.58
        )
    }

    private static func editorialJitter(for id: UUID) -> CGPoint {
        let hash = abs(id.hashValue)
        let x = CGFloat(hash % 25) - 12
        let y = CGFloat((hash / 25) % 25) - 12
        return CGPoint(x: x, y: y)
    }
}
