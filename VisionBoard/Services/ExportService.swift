import SwiftUI

struct ExportService {
    @MainActor
    static func renderBoardImage(board: VisionBoard, size: CGSize) -> UIImage? {
        let renderer = ImageRenderer(
            content: ExportableBoardView(board: board)
                .frame(width: size.width, height: size.height)
        )
        renderer.scale = 3.0 // 3x for high quality
        return renderer.uiImage
    }

    @MainActor
    static func shareBoard(_ board: VisionBoard, from view: UIView?) {
        let size: CGSize
        switch board.aspectRatio {
        case .square:
            size = CGSize(width: 1080, height: 1080)
        case .portrait:
            size = CGSize(width: 1080, height: 1920)
        }

        guard let image = renderBoardImage(board: board, size: size) else { return }

        let watermarkedImage = addWatermark(to: image, appName: "愿景板 App")

        let activityVC = UIActivityViewController(
            activityItems: [watermarkedImage],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            var topVC = rootVC
            while let presented = topVC.presentedViewController {
                topVC = presented
            }
            activityVC.popoverPresentationController?.sourceView = view ?? topVC.view
            topVC.present(activityVC, animated: true)
        }
    }

    static func addWatermark(to image: UIImage, appName: String) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { context in
            image.draw(at: .zero)

            let text = "用 \(appName) 制作"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: image.size.width * 0.025, weight: .medium),
                .foregroundColor: UIColor.white.withAlphaComponent(0.6)
            ]

            let textSize = (text as NSString).size(withAttributes: attributes)
            let point = CGPoint(
                x: image.size.width - textSize.width - image.size.width * 0.03,
                y: image.size.height - textSize.height - image.size.width * 0.03
            )
            (text as NSString).draw(at: point, withAttributes: attributes)
        }
    }
}

// MARK: - Exportable View

struct ExportableBoardView: View {
    let board: VisionBoard

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    colors: [Color(hex: board.backgroundColor),
                             Color(hex: board.backgroundGradientEnd ?? board.backgroundColor)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                ForEach(board.items.sorted(by: { $0.zIndex < $1.zIndex })) { item in
                    BoardItemView(item: item, canvasSize: geo.size)
                }
            }
        }
    }
}
