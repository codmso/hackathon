import SwiftUI

struct CanvasView: UIViewControllerRepresentable {
    let memories: [Memory]
    var onSelectMemory: (Memory) -> Void
    var onPositionChanged: (Memory, Double, Double) -> Void

    func makeUIViewController(context: Context) -> CanvasViewController {
        let controller = CanvasViewController()
        controller.memories = memories
        controller.onSelectMemory = onSelectMemory
        controller.onPositionChanged = onPositionChanged
        return controller
    }

    func updateUIViewController(_ uiViewController: CanvasViewController, context: Context) {
        uiViewController.onSelectMemory = onSelectMemory
        uiViewController.onPositionChanged = onPositionChanged
        uiViewController.updateMemories(memories)
    }
}
