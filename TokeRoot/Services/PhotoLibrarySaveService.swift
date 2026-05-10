import PencilKit
import Photos
import UIKit

enum PhotoLibrarySaveError: Error {
    case emptyDrawing
    case permissionDenied
    case saveFailed
}

extension PhotoLibrarySaveError {
    var studentMessage: String {
        switch self {
        case .emptyDrawing:
            return "まだ何も書かれていません。"
        case .permissionDenied:
            return "写真への保存が許可されていません。設定から許可できます。"
        case .saveFailed:
            return "写真への保存で問題が起きました。もう一度試してください。"
        }
    }
}

@MainActor
struct PhotoLibrarySaveService {
    static let shared = PhotoLibrarySaveService()

    func saveDrawing(from canvas: PKCanvasView) async throws {
        let image = try image(from: canvas)
        let status = await requestAddOnlyAccessIfNeeded()
        guard status == .authorized || status == .limited else {
            throw PhotoLibrarySaveError.permissionDenied
        }

        try await withCheckedThrowingContinuation { continuation in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: error ?? PhotoLibrarySaveError.saveFailed)
                }
            }
        }
    }

    private func image(from canvas: PKCanvasView) throws -> UIImage {
        guard !canvas.drawing.bounds.isEmpty else {
            throw PhotoLibrarySaveError.emptyDrawing
        }

        let size = canvas.bounds.size.width > 1 && canvas.bounds.size.height > 1
            ? canvas.bounds.size
            : CGSize(width: 1000, height: 1300)
        let rect = CGRect(origin: .zero, size: size)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = UIScreen.main.scale

        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor.white.setFill()
            context.fill(rect)
            canvas.drawing
                .image(from: rect, scale: format.scale)
                .draw(in: rect)
        }
    }

    private func requestAddOnlyAccessIfNeeded() async -> PHAuthorizationStatus {
        let current = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        guard current == .notDetermined else { return current }

        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                continuation.resume(returning: status)
            }
        }
    }
}
