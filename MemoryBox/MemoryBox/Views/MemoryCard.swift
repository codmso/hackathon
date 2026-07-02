import SwiftUI

struct MemoryCard: View {
    enum Style {
        case shelf
        case compact
    }

    let memory: Memory
    var style: Style = .shelf
    var onTap: (() -> Void)?

    var body: some View {
        Button {
            onTap?()
        } label: {
            cardContent
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var cardContent: some View {
        switch style {
        case .shelf:
            shelfCard
        case .compact:
            compactCard
        }
    }

    private var shelfCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            shelfImageSection
                .frame(width: 140, height: 126)
                .clipped()
            VStack(alignment: .leading, spacing: 4) {
                Text(memory.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                    .foregroundStyle(.primary)
                Text(DateFormatters.monthDay.string(from: memory.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(width: 140, height: 54, alignment: .topLeading)
        }
        .frame(width: 140, height: 180)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
    }

    @ViewBuilder
    private var shelfImageSection: some View {
        if let imageData = memory.imageData, let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                Color(.secondarySystemBackground)
                Image(systemName: "photo")
                    .font(.title2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var compactCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            imageSection
            VStack(alignment: .leading, spacing: 2) {
                Text(memory.title)
                    .font(.caption.weight(.bold))
                    .lineLimit(1)
                    .foregroundStyle(.primary)
                Text(DateFormatters.year.string(from: memory.date))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .frame(width: 160, height: 120)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
    }

    @ViewBuilder
    private var imageSection: some View {
        if let imageData = memory.imageData, let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)
                .clipped()
                .layoutPriority(-1)
        } else {
            ZStack {
                Color(.secondarySystemBackground)
                Image(systemName: "photo")
                    .font(.title2)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

#Preview {
    let memory = Memory(title: "Summer Trip", note: "A wonderful day at the beach.", date: .now)
    return HStack {
        MemoryCard(memory: memory, style: .shelf)
        MemoryCard(memory: memory, style: .compact)
    }
    .padding()
}
