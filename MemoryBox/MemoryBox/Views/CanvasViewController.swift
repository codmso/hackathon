import UIKit

final class CanvasViewController: UIViewController, UIScrollViewDelegate {
    var memories: [Memory] = []
    var onSelectMemory: ((Memory) -> Void)?
    var onPositionChanged: ((Memory, Double, Double) -> Void)?

    private let canvasSize = CGSize(width: 3000, height: 3000)
    private let scrollView = UIScrollView()
    private let canvasView = UIView()
    private var stickerViews: [UUID: MemoryStickerView] = [:]
    private var draggingSticker: MemoryStickerView?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = EditorialFlatlayLayout.canvasBackground
        setupScrollView()
        setupDoubleTapGesture()
    }

    func updateMemories(_ memories: [Memory]) {
        self.memories = memories
        syncStickers()
    }

    // MARK: - Setup

    private func setupScrollView() {
        scrollView.delegate = self
        scrollView.minimumZoomScale = 0.3
        scrollView.maximumZoomScale = 3.0
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = EditorialFlatlayLayout.canvasBackground
        view.addSubview(scrollView)

        canvasView.backgroundColor = EditorialFlatlayLayout.canvasBackground
        canvasView.frame = CGRect(origin: .zero, size: canvasSize)
        scrollView.addSubview(canvasView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        scrollView.contentSize = canvasSize
    }

    private func setupDoubleTapGesture() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if scrollView.zoomScale == scrollView.minimumZoomScale && !stickerViews.isEmpty {
            centerOnFlatlay()
        }
    }

    private func centerOnFlatlay() {
        let region = CGRect(
            x: canvasSize.width * 0.18,
            y: canvasSize.height * 0.14,
            width: canvasSize.width * 0.64,
            height: canvasSize.height * 0.58
        )
        let offsetX = max(region.midX - scrollView.bounds.width / 2, 0)
        let offsetY = max(region.midY - scrollView.bounds.height / 2, 0)
        scrollView.contentOffset = CGPoint(x: offsetX, y: offsetY)
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.5) {
            self.scrollView.zoomScale = 1.0
            self.centerOnFlatlay()
        }
    }

    // MARK: - Stickers

    private func sortedMemories() -> [Memory] {
        memories.sorted { $0.date > $1.date }
    }

    private func layoutIndex(for memory: Memory) -> Int {
        sortedMemories().firstIndex(where: { $0.id == memory.id }) ?? 0
    }

    private func syncStickers() {
        let sorted = sortedMemories()
        let total = sorted.count
        let placements = EditorialFlatlayLayout.placements(for: sorted, canvasSize: canvasSize)

        let currentIDs = Set(memories.map(\.id))
        for (id, sticker) in stickerViews where !currentIDs.contains(id) {
            sticker.removeFromSuperview()
            stickerViews.removeValue(forKey: id)
        }

        applyEditorialPositions(from: placements)

        let addOrder = sorted.sorted {
            (placements[$0.id]?.style.zIndex ?? 0) < (placements[$1.id]?.style.zIndex ?? 0)
        }

        for memory in addOrder {
            let index = layoutIndex(for: memory)
            let center = CGPoint(x: memory.canvasX, y: memory.canvasY)

            if let existing = stickerViews[memory.id] {
                existing.configure(with: memory)
                if draggingSticker?.memory.id != memory.id {
                    existing.center = center
                }
            } else {
                let sticker = MemoryStickerView(memory: memory, layoutIndex: index, layoutTotal: total)
                sticker.center = center
                sticker.onTap = { [weak self] in
                    self?.onSelectMemory?(memory)
                }
                attachDragGestures(to: sticker)
                canvasView.addSubview(sticker)
                stickerViews[memory.id] = sticker
            }
        }

        for memory in addOrder {
            if let sticker = stickerViews[memory.id] {
                canvasView.bringSubviewToFront(sticker)
            }
        }
    }

    private func applyEditorialPositions(from placements: [UUID: EditorialFlatlayLayout.Placement]) {
        for memory in memories {
            guard !memory.canvasPlacementIsCustom,
                  let placement = placements[memory.id] else { continue }

            let newX = placement.center.x
            let newY = placement.center.y
            guard memory.canvasX != newX || memory.canvasY != newY else { continue }

            memory.canvasX = newX
            memory.canvasY = newY
            onPositionChanged?(memory, newX, newY)
        }
    }

    private func attachDragGestures(to sticker: MemoryStickerView) {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.35
        sticker.addGestureRecognizer(longPress)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.isEnabled = false
        sticker.panGesture = pan
        sticker.addGestureRecognizer(pan)

        let tap = UITapGestureRecognizer(target: sticker, action: #selector(MemoryStickerView.handleTap))
        tap.require(toFail: longPress)
        sticker.addGestureRecognizer(tap)
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard let sticker = gesture.view as? MemoryStickerView else { return }

        switch gesture.state {
        case .began:
            draggingSticker = sticker
            sticker.panGesture?.isEnabled = true
            sticker.setDragging(true)
            canvasView.bringSubviewToFront(sticker)
        case .ended, .cancelled, .failed:
            if draggingSticker === sticker {
                finishDragging(sticker)
            }
        default:
            break
        }
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let sticker = gesture.view as? MemoryStickerView else { return }
        let translation = gesture.translation(in: canvasView)

        switch gesture.state {
        case .changed:
            sticker.center = CGPoint(
                x: sticker.center.x + translation.x,
                y: sticker.center.y + translation.y
            )
            gesture.setTranslation(.zero, in: canvasView)
        case .ended, .cancelled:
            finishDragging(sticker)
        default:
            break
        }
    }

    private func finishDragging(_ sticker: MemoryStickerView) {
        sticker.panGesture?.isEnabled = false
        sticker.setDragging(false)
        draggingSticker = nil

        let halfSize = sticker.itemSize / 2
        let clampedX = min(max(sticker.center.x, halfSize), canvasSize.width - halfSize)
        let clampedY = min(max(sticker.center.y, halfSize), canvasSize.height - halfSize)

        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.72,
            initialSpringVelocity: 0.4
        ) {
            sticker.center = CGPoint(x: clampedX, y: clampedY)
        }

        sticker.memory.canvasPlacementIsCustom = true
        sticker.memory.canvasX = clampedX
        sticker.memory.canvasY = clampedY
        onPositionChanged?(sticker.memory, clampedX, clampedY)
    }

    // MARK: - UIScrollViewDelegate

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        canvasView
    }
}
