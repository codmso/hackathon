import SwiftUI
import PhotosUI

struct AddMemorySheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var date = Date.now
    @State private var note = ""
    @State private var originalImage: UIImage?
    @State private var processedImage: UIImage?
    @State private var isRemovingBackground = false
    @State private var showBackgroundRemovalAlert = false
    @State private var showPhotoPicker = false
    @State private var showCamera = false

    private let accentColor = Color(red: 232 / 255, green: 160 / 255, blue: 32 / 255)

    private var displayedImage: UIImage? {
        processedImage ?? originalImage
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Memory") {
                    TextField("Title", text: $title)
                        .onChange(of: title) { _, newValue in
                            if newValue.count > 50 {
                                title = String(newValue.prefix(50))
                            }
                        }

                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section("Note") {
                    TextEditor(text: $note)
                        .frame(minHeight: 72)
                        .onChange(of: note) { _, newValue in
                            if newValue.count > 200 {
                                note = String(newValue.prefix(200))
                            }
                        }
                }

                Section("Photo") {
                    HStack(spacing: 12) {
                        Button {
                            showPhotoPicker = true
                        } label: {
                            Label("Choose Photo", systemImage: "photo.on.rectangle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            Button {
                                showCamera = true
                            } label: {
                                Label("Take Photo", systemImage: "camera")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    if let displayedImage {
                        VStack(spacing: 12) {
                            ZStack(alignment: .topTrailing) {
                                ZStack {
                                    CheckerboardBackground()
                                        .frame(width: 200, height: 200)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))

                                    Image(uiImage: displayedImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 200, height: 200)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))

                                    if isRemovingBackground {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.black.opacity(0.35))
                                            .frame(width: 200, height: 200)
                                        ProgressView()
                                            .tint(.white)
                                    }
                                }

                                Button {
                                    clearImage()
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title2)
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.white, .black.opacity(0.6))
                                }
                                .offset(x: 8, y: -8)
                                .disabled(isRemovingBackground)
                            }

                            HStack(spacing: 12) {
                                Button {
                                    removeBackground()
                                } label: {
                                    Label("Remove background", systemImage: "wand.and.rays")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .disabled(isRemovingBackground)

                                if processedImage != nil {
                                    Button {
                                        processedImage = nil
                                    } label: {
                                        Label("Reset", systemImage: "arrow.uturn.backward")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.bordered)
                                    .disabled(isRemovingBackground)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    }
                }
            }
            .navigationTitle("New Memory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveMemory() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .fontWeight(.semibold)
                        .foregroundStyle(accentColor)
                }
            }
            .sheet(isPresented: $showPhotoPicker) {
                PhotoPickerView { image in
                    setSelectedImage(image)
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPickerView { image in
                    setSelectedImage(image)
                }
                .ignoresSafeArea()
            }
            .alert(
                "Background Removal Unavailable",
                isPresented: $showBackgroundRemovalAlert
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Background removal isn't available in Simulator. Try on a real device.")
            }
        }
    }

    private func setSelectedImage(_ image: UIImage) {
        originalImage = image
        processedImage = nil
    }

    private func clearImage() {
        originalImage = nil
        processedImage = nil
    }

    private func removeBackground() {
        guard let sourceImage = originalImage else { return }

        isRemovingBackground = true
        Task {
            let result = await Task.detached(priority: .userInitiated) {
                BackgroundRemover.removeBackground(from: sourceImage)
            }.value

            await MainActor.run {
                isRemovingBackground = false
                if let result {
                    processedImage = result
                } else {
                    showBackgroundRemovalAlert = true
                }
            }
        }
    }

    private func saveMemory() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let imageData: Data?
        if let processedImage {
            imageData = processedImage.pngData()
        } else if let originalImage {
            imageData = originalImage.jpegData(compressionQuality: 0.7)
        } else {
            imageData = nil
        }

        let memory = Memory(
            title: trimmedTitle,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            date: date,
            imageData: imageData
        )
        modelContext.insert(memory)
        dismiss()
    }
}

private struct CheckerboardBackground: View {
    private let squareSize: CGFloat = 10

    var body: some View {
        Canvas { context, size in
            let columns = Int(ceil(size.width / squareSize))
            let rows = Int(ceil(size.height / squareSize))

            for row in 0..<rows {
                for column in 0..<columns {
                    let isLight = (row + column).isMultiple(of: 2)
                    let rect = CGRect(
                        x: CGFloat(column) * squareSize,
                        y: CGFloat(row) * squareSize,
                        width: squareSize,
                        height: squareSize
                    )
                    context.fill(
                        Path(rect),
                        with: .color(isLight ? Color(white: 0.92) : Color(white: 0.78))
                    )
                }
            }
        }
    }
}

private struct PhotoPickerView: UIViewControllerRepresentable {
    let onImagePicked: (UIImage) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked)
    }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onImagePicked: (UIImage) -> Void

        init(onImagePicked: @escaping (UIImage) -> Void) {
            self.onImagePicked = onImagePicked
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }

            provider.loadObject(ofClass: UIImage.self) { object, _ in
                guard let image = object as? UIImage else { return }
                DispatchQueue.main.async {
                    self.onImagePicked(image)
                }
            }
        }
    }
}

private struct CameraPickerView: UIViewControllerRepresentable {
    let onImagePicked: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked, dismiss: dismiss)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImagePicked: (UIImage) -> Void
        let dismiss: DismissAction

        init(onImagePicked: @escaping (UIImage) -> Void, dismiss: DismissAction) {
            self.onImagePicked = onImagePicked
            self.dismiss = dismiss
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                onImagePicked(image)
            }
            dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}
