import SwiftUI

struct GravityView: UIViewControllerRepresentable {
    let memories: [Memory]
    var onSelectMemory: (Memory) -> Void

    func makeUIViewController(context: Context) -> GravityViewController {
        let controller = GravityViewController()
        controller.memories = Array(memories.sorted { $0.createdAt > $1.createdAt }.prefix(10))
        controller.onSelectMemory = onSelectMemory
        return controller
    }

    func updateUIViewController(_ uiViewController: GravityViewController, context: Context) {
        uiViewController.onSelectMemory = onSelectMemory
        uiViewController.updateMemories(memories)
    }
}
