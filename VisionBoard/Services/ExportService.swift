import SwiftUI

struct ExportService {
    @MainActor
    static func shareBoard(_ board: VisionBoard, size: CGSize, from view: UIView?) {
        let renderer = ImageRenderer(
            content: TemplateBoardRenderer(board: board)
                .frame(width: size.width, height: size.height)
        )
        renderer.scale = 3.0
        guard let image = renderer.uiImage else { return }

        let isPro = StoreKitManager.shared.isPro
        let finalImage = isPro ? image : addWatermark(to: image)

        let activityVC = UIActivityViewController(
            activityItems: [finalImage],
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

    static func addWatermark(to image: UIImage) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { _ in
            image.draw(at: .zero)
            let text = "用 愿景板 App 制作"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: image.size.width * 0.022, weight: .medium),
                .foregroundColor: UIColor.white.withAlphaComponent(0.55)
            ]
            let textSize = (text as NSString).size(withAttributes: attrs)
            let point = CGPoint(
                x: image.size.width - textSize.width - image.size.width * 0.03,
                y: image.size.height - textSize.height - image.size.width * 0.03
            )
            (text as NSString).draw(at: point, withAttributes: attrs)
        }
    }
}
