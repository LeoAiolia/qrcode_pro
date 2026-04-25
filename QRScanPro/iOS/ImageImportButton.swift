import PhotosUI
import SwiftUI

struct ImageImportButton: View {
    let isLoading: Bool
    let onImageSelected: (CGImage) -> Void

    @State private var isPickerPresented = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                isPickerPresented = true
            } label: {
                Label(isLoading ? "识别中" : "选择图片", systemImage: "photo")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading)
            .sheet(isPresented: $isPickerPresented) {
                PhotoPicker { result in
                    switch result {
                    case .success(let image):
                        onImageSelected(image)
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                    }
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(AppTheme.warning)
            }
        }
    }
}

struct PhotoPicker: UIViewControllerRepresentable {
    let completion: (Result<CGImage, Error>) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 1

        let controller = PHPickerViewController(configuration: configuration)
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let completion: (Result<CGImage, Error>) -> Void

        init(completion: @escaping (Result<CGImage, Error>) -> Void) {
            self.completion = completion
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard let provider = results.first?.itemProvider else {
                return
            }

            guard provider.canLoadObject(ofClass: UIImage.self) else {
                completion(.failure(ImageRecognitionError.invalidImage))
                return
            }

            provider.loadObject(ofClass: UIImage.self) { object, error in
                if let error {
                    DispatchQueue.main.async {
                        self.completion(.failure(error))
                    }
                    return
                }

                guard let image = object as? UIImage, let cgImage = image.cgImage else {
                    DispatchQueue.main.async {
                        self.completion(.failure(ImageRecognitionError.invalidImage))
                    }
                    return
                }

                DispatchQueue.main.async {
                    self.completion(.success(cgImage))
                }
            }
        }
    }
}
