import Photos
import UIKit

enum PhotoLibrarySaverError: LocalizedError {
    case unauthorized
    case writeFailed(String)

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "未授予相册写入权限，请在「设置」中开启"
        case .writeFailed(let message):
            return "保存到相册失败：\(message)"
        }
    }
}

enum PhotoLibrarySaver {
    static func save(_ image: UIImage) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        switch status {
        case .authorized, .limited:
            break
        case .denied, .restricted, .notDetermined:
            throw PhotoLibrarySaverError.unauthorized
        @unknown default:
            throw PhotoLibrarySaverError.unauthorized
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { isSuccess, error in
                if isSuccess {
                    continuation.resume()
                } else if let error {
                    continuation.resume(throwing: PhotoLibrarySaverError.writeFailed(error.localizedDescription))
                } else {
                    continuation.resume(throwing: PhotoLibrarySaverError.writeFailed("未知错误"))
                }
            }
        }
    }
}
