import SwiftUI

struct TileView: View {
    let title: String
    let subtitle: String
    let symbol: String
    var badgeText: String? = nil
    var iconColor: Color = .blue
    var badgeColor: Color = .secondary

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: symbol)
                    .font(.title2)
                    .foregroundStyle(iconColor)

                Spacer()

                if let badgeText {
                    Text(badgeText)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(badgeColor.opacity(0.14), in: Capsule())
                        .foregroundStyle(badgeColor)
                }
            }

            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(2)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 170, maxHeight: 170)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.cardBG)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(uiColor: .separator).opacity(0.35), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
