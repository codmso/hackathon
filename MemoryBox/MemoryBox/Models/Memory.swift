import Foundation
import SwiftData

@Model
class Memory {
    var id: UUID
    var title: String
    var note: String
    var date: Date
    var imageData: Data?
    var canvasX: Double
    var canvasY: Double
    var canvasPlacementIsCustom: Bool = false
    var createdAt: Date

    init(title: String, note: String = "", date: Date = .now, imageData: Data? = nil) {
        self.id = UUID()
        self.title = title
        self.note = note
        self.date = date
        self.imageData = imageData
        self.canvasX = 0
        self.canvasY = 0
        self.canvasPlacementIsCustom = false
        self.createdAt = .now
    }
}
