import UIKit

final class GravityViewController: UIViewController {
    var memories: [Memory] = []
    var onSelectMemory: ((Memory) -> Void)?

    private var animator: UIDynamicAnimator!
    private var gravity: UIGravityBehavior!
    private var collision: UICollisionBehavior!
    private var itemBehavior: UIDynamicItemBehavior!
    private var stickerViews: [UUID: MemoryStickerView] = [:]
    private var hasDropped = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = EditorialFlatlayLayout.canvasBackground
        view.insetsLayoutMarginsFromSafeArea = false
        setupDynamics()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !hasDropped {
            dropStickers()
            hasDropped = true
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCollisionBoundaries()
    }

    func updateMemories(_ memories: [Memory]) {
        let recent = Array(memories.sorted { $0.createdAt > $1.createdAt }.prefix(10))
        let changed = recent.map(\.id) != self.memories.map(\.id)
        self.memories = recent

        if changed {
            resetStickers()
        }
    }

    // MARK: - Dynamics

    private func setupDynamics() {
        animator = UIDynamicAnimator(referenceView: view)

        gravity = UIGravityBehavior()
        gravity.magnitude = 0.85
        animator.addBehavior(gravity)

        collision = UICollisionBehavior()
        collision.translatesReferenceBoundsIntoBoundary = false
        animator.addBehavior(collision)

        itemBehavior = UIDynamicItemBehavior()
        itemBehavior.elasticity = 0.22
        itemBehavior.friction = 0.55
        itemBehavior.resistance = 0.35
        animator.addBehavior(itemBehavior)
    }

    private func updateCollisionBoundaries() {
        collision.removeAllBoundaries()
        guard view.bounds.width > 0 else { return }

        let width = view.bounds.width
        let bottomY = screenBottomY()

        collision.addBoundary(
            withIdentifier: "left" as NSCopying,
            from: CGPoint(x: 0, y: 0),
            to: CGPoint(x: 0, y: bottomY)
        )
        collision.addBoundary(
            withIdentifier: "right" as NSCopying,
            from: CGPoint(x: width, y: 0),
            to: CGPoint(x: width, y: bottomY)
        )
        collision.addBoundary(
            withIdentifier: "bottom" as NSCopying,
            from: CGPoint(x: 0, y: bottomY),
            to: CGPoint(x: width, y: bottomY)
        )
    }

    private func screenBottomY() -> CGFloat {
        if let window = view.window {
            return view.convert(CGPoint(x: 0, y: window.bounds.height), from: nil).y
        }
        return view.bounds.height
    }

    private func resetStickers() {
        for sticker in stickerViews.values {
            gravity.removeItem(sticker)
            collision.removeItem(sticker)
            itemBehavior.removeItem(sticker)
            sticker.removeFromSuperview()
        }
        stickerViews.removeAll()
        hasDropped = false

        if view.window != nil {
            dropStickers()
            hasDropped = true
        }
    }

    private func dropStickers() {
        let total = memories.count

        for (index, memory) in memories.enumerated() {
            let dropPoint = EditorialFlatlayLayout.gravityDropCenter(
                for: index,
                total: total,
                viewWidth: view.bounds.width
            )
            let sticker = MemoryStickerView(memory: memory, layoutIndex: index, layoutTotal: total)
            sticker.center = dropPoint
            sticker.onTap = { [weak self] in
                self?.onSelectMemory?(memory)
            }
            view.addSubview(sticker)
            attachGestures(to: sticker)
            stickerViews[memory.id] = sticker

            gravity.addItem(sticker)
            collision.addItem(sticker)
            itemBehavior.addItem(sticker)
        }
    }

    private func attachGestures(to sticker: MemoryStickerView) {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        sticker.addGestureRecognizer(pan)

        let tap = UITapGestureRecognizer(target: sticker, action: #selector(MemoryStickerView.handleTap))
        tap.require(toFail: pan)
        sticker.addGestureRecognizer(tap)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let sticker = gesture.view as? MemoryStickerView else { return }
        let location = gesture.location(in: view)
        let rotation = sticker.rotationAngle

        switch gesture.state {
        case .began:
            gravity.removeItem(sticker)
            collision.removeItem(sticker)
            itemBehavior.removeItem(sticker)
            sticker.center = location
            sticker.transform = CGAffineTransform(rotationAngle: rotation)
        case .changed:
            sticker.center = location
            sticker.transform = CGAffineTransform(rotationAngle: rotation)
        case .ended, .cancelled:
            sticker.applyRotation()
            gravity.addItem(sticker)
            collision.addItem(sticker)
            itemBehavior.addItem(sticker)
        default:
            break
        }
    }
}
