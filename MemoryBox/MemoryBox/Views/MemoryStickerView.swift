import UIKit

final class MemoryStickerView: UIView {
    let memory: Memory
    let layoutIndex: Int
    let layoutTotal: Int
    var onTap: (() -> Void)?
    var panGesture: UIPanGestureRecognizer?

    private let imageView = UIImageView()
    private let placeholderBackground = UIView()

    private var itemStyle: EditorialFlatlayLayout.ItemStyle {
        EditorialFlatlayLayout.itemStyle(at: layoutIndex, total: layoutTotal)
    }

    var itemSize: CGFloat { itemStyle.size }
    var rotationAngle: CGFloat { itemStyle.rotation }

    init(memory: Memory, layoutIndex: Int, layoutTotal: Int) {
        self.memory = memory
        self.layoutIndex = layoutIndex
        self.layoutTotal = layoutTotal
        let style = EditorialFlatlayLayout.itemStyle(at: layoutIndex, total: layoutTotal)
        super.init(frame: CGRect(x: 0, y: 0, width: style.size, height: style.size))
        setup()
        configure(with: memory)
        applyRotation()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        backgroundColor = .clear
        clipsToBounds = false
        applyShadow(dragging: false)

        placeholderBackground.backgroundColor = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(white: 0.14, alpha: 1)
                : UIColor(white: 0.96, alpha: 1)
        }
        placeholderBackground.layer.cornerRadius = 0
        placeholderBackground.translatesAutoresizingMaskIntoConstraints = false
        placeholderBackground.isHidden = true
        addSubview(placeholderBackground)

        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = false
        imageView.backgroundColor = .clear
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)

        NSLayoutConstraint.activate([
            placeholderBackground.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            placeholderBackground.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            placeholderBackground.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            placeholderBackground.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),

            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    func configure(with memory: Memory) {
        if let data = memory.imageData, let image = UIImage(data: data) {
            imageView.image = image
            imageView.contentMode = .scaleAspectFit
            imageView.tintColor = nil
            placeholderBackground.isHidden = true
        } else {
            imageView.image = UIImage(systemName: "photo.on.rectangle.angled")
            imageView.contentMode = .center
            imageView.tintColor = .tertiaryLabel
            placeholderBackground.isHidden = false
        }
    }

    func applyRotation() {
        transform = CGAffineTransform(rotationAngle: rotationAngle)
    }

    func setDragging(_ dragging: Bool) {
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut) {
            let scale: CGFloat = dragging ? 1.05 : 1.0
            self.transform = CGAffineTransform(rotationAngle: self.rotationAngle).scaledBy(x: scale, y: scale)
            self.applyShadow(dragging: dragging)
        }
    }

    private func applyShadow(dragging: Bool) {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = dragging ? 0.1 : 0.05
        layer.shadowRadius = dragging ? 12 : 16
        layer.shadowOffset = CGSize(width: 0, height: dragging ? 4 : 2)
    }

    @objc func handleTap() {
        onTap?()
    }
}
