import SwiftUI
import SwiftData
import UIKit

struct ContentView: View {
    @Query(sort: \Memory.date, order: .reverse) private var memories: [Memory]
    @State private var showAddSheet = false
    @State private var selectedMemory: Memory?

    private let accentColor = Color(red: 232 / 255, green: 160 / 255, blue: 32 / 255)

    var body: some View {
        TabView {
            NavigationStack {
                gravityTab
            }
            .tabItem {
                Label("Gravity", systemImage: "square.3.layers.3d.down.right")
            }

            NavigationStack {
                canvasTab
            }
            .tabItem {
                Label("Canvas", systemImage: "rectangle.3.group")
            }

            NavigationStack {
                ShelfView(
                    memories: memories,
                    onAddMemory: { showAddSheet = true },
                    onSelectMemory: { selectedMemory = $0 }
                )
            }
            .tabItem {
                Label("Shelf", systemImage: "books.vertical")
            }
        }
        .tint(accentColor)
        .sheet(isPresented: $showAddSheet) {
            AddMemorySheet()
        }
        .sheet(item: $selectedMemory) { memory in
            MemoryDetailSheet(memory: memory)
        }
    }

    @ViewBuilder
    private var gravityTab: some View {
        if memories.isEmpty {
            emptyState(
                icon: "square.3.layers.3d.down.right",
                title: "No memories yet"
            )
            .navigationTitle("Gravity")
            .toolbar { addToolbarItem }
        } else {
            GravityView(memories: memories) { memory in
                selectedMemory = memory
            }
            .ignoresSafeArea(.container, edges: .bottom)
            .background(Color(uiColor: EditorialFlatlayLayout.canvasBackground))
            .navigationTitle("Gravity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { addToolbarItem }
        }
    }

    @ViewBuilder
    private var canvasTab: some View {
        if memories.isEmpty {
            emptyState(
                icon: "rectangle.3.group",
                title: "No memories yet"
            )
            .navigationTitle("Canvas")
            .toolbar { addToolbarItem }
        } else {
            CanvasView(
                memories: memories,
                onSelectMemory: { selectedMemory = $0 },
                onPositionChanged: { memory, x, y in
                    memory.canvasX = x
                    memory.canvasY = y
                }
            )
            .ignoresSafeArea(.container, edges: .bottom)
            .background(Color(uiColor: EditorialFlatlayLayout.canvasBackground))
            .navigationTitle("Canvas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { addToolbarItem }
        }
    }

    private var addToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                showAddSheet = true
            } label: {
                Image(systemName: "plus")
                    .foregroundStyle(accentColor)
            }
        }
    }

    private func emptyState(icon: String, title: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundStyle(.tertiary)
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
            Button("Add your first memory") {
                showAddSheet = true
            }
            .buttonStyle(.borderedProminent)
            .tint(accentColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

extension Memory: Identifiable {}

#Preview {
    ContentView()
        .modelContainer(PreviewContainer.shared)
}

@MainActor
private enum PreviewContainer {
    static let shared: ModelContainer = {
        let container = try! ModelContainer(
            for: Memory.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let calendar = Calendar.current
        let samples: [(String, String, Date)] = [
            ("Beach Day", "Collected shells at sunset.", calendar.date(byAdding: .day, value: -12, to: .now)!),
            ("Birthday Party", "Cake, candles, and good friends.", calendar.date(byAdding: .month, value: -2, to: .now)!),
            ("Mountain Hike", "Reached the summit before noon.", calendar.date(byAdding: .month, value: -5, to: .now)!),
            ("First Day", "Started something new.", calendar.date(from: DateComponents(year: 2024, month: 3, day: 15))!),
            ("Winter Walk", "Fresh snow in the park.", calendar.date(from: DateComponents(year: 2024, month: 12, day: 8))!),
            ("Road Trip", "Highway, music, and open sky.", calendar.date(from: DateComponents(year: 2023, month: 7, day: 22))!),
        ]

        for (title, note, date) in samples {
            let memory = Memory(title: title, note: note, date: date)
            context.insert(memory)
        }

        return container
    }()
}
