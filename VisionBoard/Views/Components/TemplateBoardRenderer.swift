import SwiftUI

struct TemplateBoardRenderer: View {
    let board: VisionBoard

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)

            ZStack(alignment: .topLeading) {
                LinearGradient(
                    colors: [Color(hex: board.backgroundColor),
                             Color(hex: board.backgroundGradientEnd ?? board.backgroundColor)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                if let template = board.template {
                    ForEach(template.slots) { slot in
                        photoView(slot: slot, side: side)
                            .frame(width: side * slot.width, height: side * slot.height)
                            .padding(.leading, side * slot.x)
                            .padding(.top, side * slot.y)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    }

                    ForEach(template.textSlots) { slot in
                        textView(slot: slot, side: side)
                            .frame(width: side * slot.width)
                            .padding(.leading, side * (slot.x - slot.width / 2))
                            .padding(.top, side * slot.y - slot.fontSize * (side / 400) / 2)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    }
                }
            }
            .frame(width: side, height: side)
        }
    }

    private func photoView(slot: TemplateSlot, side: CGFloat) -> some View {
        let scaledRadius = slot.cornerRadius * (side / 400)

        return ZStack {
            if let data = board.photoData(forSlot: slot.id),
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: side * slot.width, height: side * slot.height)
                    .clipped()
            } else {
                Color.white.opacity(0.15)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: side * 0.04))
                            .foregroundStyle(.white.opacity(0.3))
                    )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: scaledRadius))
    }

    private func textView(slot: TemplateTextSlot, side: CGFloat) -> some View {
        let content = board.textContent(forSlot: slot.id)
        let displayText = content ?? slot.placeholder
        let isPlaceholder = content == nil
        let scaledFontSize = slot.fontSize * (side / 400)
        let textColor = board.adaptiveTextColor

        return Text(displayText)
            .font(.system(size: scaledFontSize, weight: slot.fontWeight))
            .foregroundStyle(
                Color(hex: textColor).opacity(isPlaceholder ? 0.4 : 1.0)
            )
            .shadow(color: .black.opacity(board.isBackgroundLight ? 0 : 0.3), radius: 2, x: 0, y: 1)
            .multilineTextAlignment(slot.alignment)
            .lineLimit(3)
    }
}
