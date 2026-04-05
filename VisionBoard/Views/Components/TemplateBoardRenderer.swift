import SwiftUI

struct TemplateBoardRenderer: View {
    let board: VisionBoard

    var body: some View {
        GeometryReader { geo in
            let size = geo.size

            ZStack {
                // Background
                LinearGradient(
                    colors: [Color(hex: board.backgroundColor),
                             Color(hex: board.backgroundGradientEnd ?? board.backgroundColor)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                if let template = board.template {
                    // Photo slots
                    ForEach(template.slots) { slot in
                        photoView(slot: slot, canvasSize: size)
                    }

                    // Text slots
                    ForEach(template.textSlots) { slot in
                        textView(slot: slot, canvasSize: size)
                    }
                }
            }
        }
    }

    private func photoView(slot: TemplateSlot, canvasSize: CGSize) -> some View {
        let scaledRadius = slot.cornerRadius * (canvasSize.width / 400)

        return Group {
            if let data = board.photoData(forSlot: slot.id),
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                // Empty slot in preview — subtle placeholder
                Color.white.opacity(0.15)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: canvasSize.width * 0.04))
                            .foregroundStyle(.white.opacity(0.3))
                    )
            }
        }
        .frame(
            width: canvasSize.width * slot.width,
            height: canvasSize.height * slot.height
        )
        .clipShape(RoundedRectangle(cornerRadius: scaledRadius))
        .position(
            x: canvasSize.width * (slot.x + slot.width / 2),
            y: canvasSize.height * (slot.y + slot.height / 2)
        )
    }

    private func textView(slot: TemplateTextSlot, canvasSize: CGSize) -> some View {
        let content = board.textContent(forSlot: slot.id)
        let displayText = content ?? slot.placeholder
        let isPlaceholder = content == nil
        let scaledFontSize = slot.fontSize * (canvasSize.width / 400)

        return Text(displayText)
            .font(.system(size: scaledFontSize, weight: slot.fontWeight))
            .foregroundStyle(
                Color(hex: slot.defaultColor)
                    .opacity(isPlaceholder ? 0.4 : 1.0)
            )
            .multilineTextAlignment(slot.alignment)
            .frame(width: canvasSize.width * slot.width)
            .lineLimit(3)
            .position(
                x: canvasSize.width * slot.x,
                y: canvasSize.height * slot.y
            )
    }
}
