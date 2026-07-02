import SwiftUI

struct MemoryDetailSheet: View {
    let memory: Memory
    @Environment(\.dismiss) private var dismiss

    private let accentColor = Color(red: 232 / 255, green: 160 / 255, blue: 32 / 255)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let imageData = memory.imageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 260)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(memory.title)
                            .font(.title2.weight(.bold))

                        Label(DateFormatters.fullDate.string(from: memory.date), systemImage: "calendar")
                            .font(.subheadline)
                            .foregroundStyle(accentColor)
                    }

                    if !memory.note.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Note")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            Text(memory.note)
                                .font(.body)
                                .foregroundStyle(.primary)
                        }
                    }

                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Memory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    MemoryDetailSheet(memory: Memory(title: "Beach Day", note: "Collected shells and watched the sunset.", date: .now))
}
