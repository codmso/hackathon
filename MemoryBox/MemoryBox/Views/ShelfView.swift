import SwiftUI
import SwiftData

struct ShelfView: View {
    let memories: [Memory]
    var onAddMemory: () -> Void
    var onSelectMemory: (Memory) -> Void

    private let accentColor = Color(red: 232 / 255, green: 160 / 255, blue: 32 / 255)

    private var groupedByYear: [(year: String, memories: [Memory])] {
        let grouped = Dictionary(grouping: memories) { memory in
            DateFormatters.year.string(from: memory.date)
        }
        return grouped.keys.sorted(by: >).map { year in
            (year: year, memories: grouped[year]!.sorted { $0.date > $1.date })
        }
    }

    var body: some View {
        Group {
            if memories.isEmpty {
                emptyState
            } else {
                shelfContent
            }
        }
        .navigationTitle("Shelf")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: onAddMemory) {
                    Image(systemName: "plus")
                        .foregroundStyle(accentColor)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "books.vertical")
                .font(.system(size: 64))
                .foregroundStyle(.tertiary)
            Text("No memories yet")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
            Button("Add your first memory", action: onAddMemory)
                .buttonStyle(.borderedProminent)
                .tint(accentColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var shelfContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 32) {
                ForEach(groupedByYear, id: \.year) { section in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Text(section.year)
                                .font(.system(size: 42, weight: .black, design: .serif))
                                .foregroundStyle(.secondary.opacity(0.6))
                            Rectangle()
                                .fill(Color(.separator).opacity(0.4))
                                .frame(height: 1)
                        }
                        .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(section.memories, id: \.id) { memory in
                                    MemoryCard(memory: memory, style: .shelf) {
                                        onSelectMemory(memory)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }

                        Rectangle()
                            .fill(Color(.separator).opacity(0.5))
                            .frame(height: 1)
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
    }
}

#Preview {
    NavigationStack {
        ShelfView(memories: [], onAddMemory: {}, onSelectMemory: { _ in })
    }
}
