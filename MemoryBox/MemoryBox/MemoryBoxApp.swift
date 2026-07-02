import SwiftUI
import SwiftData

@main
struct MemoryBoxApp: App {
    private let modelContainer = MemoryBoxApp.makeModelContainer()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }

    private static func makeModelContainer() -> ModelContainer {
        let schema = Schema([Memory.self])
        let configuration = ModelConfiguration(schema: schema)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // Recover from a failed lightweight migration (e.g. new property without a default).
            print("SwiftData store failed to load, resetting: \(error)")
            deletePersistentStore()
            do {
                return try ModelContainer(for: schema, configurations: [configuration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }

    private static func deletePersistentStore() {
        guard let supportURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else { return }

        for suffix in ["", "-wal", "-shm"] {
            let storeURL = supportURL.appendingPathComponent("default.store\(suffix)")
            try? FileManager.default.removeItem(at: storeURL)
        }
    }
}
