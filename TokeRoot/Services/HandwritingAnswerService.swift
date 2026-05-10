import PencilKit
import UIKit
import Vision

enum HandwritingRecognitionError: Error {
    case emptyDrawing
    case imageRenderFailed
    case noTextFound

    var studentMessage: String {
        switch self {
        case .emptyDrawing:
            return "まだ解答欄に何も書かれていません。答えを書いてから判定しましょう。"
        case .imageRenderFailed:
            return "解答欄を読み取れませんでした。もう一度書くか、下の入力欄に答えを書いてください。"
        case .noTextFound:
            return "文字を読み取れませんでした。少し大きめに書くか、下の入力欄で直してください。"
        }
    }
}

/// Reads only the final-answer canvas. The scratch memo is never sent or
/// recognized, which keeps a future API fallback cheap and privacy-friendly.
struct HandwritingAnswerService {
    static let shared = HandwritingAnswerService()

    func recognizeAnswer(from canvas: PKCanvasView) throws -> String {
        guard !canvas.drawing.bounds.isEmpty else {
            throw HandwritingRecognitionError.emptyDrawing
        }

        let image = answerImage(from: canvas)
        guard let cgImage = image.cgImage else {
            throw HandwritingRecognitionError.imageRenderFailed
        }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        request.revision = VNRecognizeTextRequestRevision3

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        let text = (request.results ?? [])
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else {
            throw HandwritingRecognitionError.noTextFound
        }

        return normalized(text)
    }

    private func answerImage(from canvas: PKCanvasView) -> UIImage {
        let rect = canvas.bounds.isEmpty
            ? canvas.drawing.bounds.insetBy(dx: -32, dy: -24)
            : canvas.bounds
        let drawingImage = canvas.drawing.image(from: rect, scale: UIScreen.main.scale)

        let renderer = UIGraphicsImageRenderer(size: drawingImage.size)
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: drawingImage.size))
            drawingImage.draw(in: CGRect(origin: .zero, size: drawingImage.size))
        }
    }

    private func normalized(_ value: String) -> String {
        let halfWidth = value.applyingTransform(.fullwidthToHalfwidth, reverse: false) ?? value
        return halfWidth
            .replacingOccurrences(of: "−", with: "-")
            .replacingOccurrences(of: "ー", with: "-")
            .replacingOccurrences(of: "＝", with: "=")
            .replacingOccurrences(of: " ", with: "")
    }
}
