//
//  AcknowledgementsView.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/6/15.
//

import SwiftUI

struct AcknowledgementsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @ObservedObject private var settings = AppSettings.shared
    @State private var isSpecialThanksExpanded = false

    private let xiaohongshuProfileURL = "https://www.xiaohongshu.com/user/profile/592cc6f56a6a6952cc7181d6?xsec_token=YBJ4MSYCgzvY8_vTPOlJJK71dmYXtJktTeY330ZPyl5x0=&xsec_source=app_share&xhsshare=CopyLink&shareRedId=Nz80Q0Y7Sj48SDtDP0E1OElGQDg8Nko_&apptime=1775933888&share_id=3bab167e879d4963a9c37aa7e011e60c"

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedGradientBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        header

                        specialThanksCard

                        platformList

                        closingCard
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 30)
                    .padding(.bottom, 48)
                }
            }
            .navigationTitle(L("settings.acknowledgements"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L("common.done")) {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .preferredColorScheme(settings.currentColorScheme)
    }

    private var header: some View {
        VStack(spacing: 18) {
            ZStack {
                HStack(spacing: -10) {
                    HeaderIcon(imageName: "XiaohongshuIcon", size: 58, cornerRadius: 16, fullBleed: true)
                        .rotationEffect(.degrees(-7))

                    HeaderIcon(imageName: "AppLogo", size: 72, padding: 0, cornerRadius: 16, fullBleed: true)
                        .zIndex(1)

                    HeaderIcon(imageName: "XiaoheiheIcon", cornerRadius: 16)
                        .rotationEffect(.degrees(7))
                }
            }

            VStack(spacing: 7) {
                Text(L("acknowledgements.hero.title"))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.80)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                Text(L("acknowledgements.hero.subtitle"))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white.opacity(0.58))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var noteCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(red: 1.0, green: 0.74, blue: 0.38))

                Text(L("acknowledgements.note.title"))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.72))
                    .textCase(.uppercase)
            }

            Text(L("acknowledgements.note.body"))
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.92))
                .lineSpacing(7)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            Color.clear
                .glassCard(cornerRadius: 26, tintColor: Color(red: 0.25, green: 0.42, blue: 0.72).opacity(0.20))
        }
    }

    private var specialThanksCard: some View {
        let heartGradient = LinearGradient(
            colors: [
                Color(red: 1.0, green: 0.50, blue: 0.62),
                Color(red: 1.0, green: 0.22, blue: 0.40)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(heartGradient)
                    .frame(width: 36, height: 36)
                    .background {
                        Circle()
                            .fill(Color(red: 1.0, green: 0.30, blue: 0.46).opacity(0.16))
                    }
                    .overlay {
                        Circle()
                            .strokeBorder(Color(red: 1.0, green: 0.40, blue: 0.54).opacity(0.28), lineWidth: 0.8)
                    }

                VStack(alignment: .leading, spacing: 3) {
                    Text(L("acknowledgements.love.title"))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 1.0, green: 0.58, blue: 0.68).opacity(0.92))
                        .textCase(.uppercase)
                        .tracking(1.4)

                    Text(L("acknowledgements.love.subtitle"))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.94))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.down")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white.opacity(0.44))
                    .rotationEffect(.degrees(isSpecialThanksExpanded ? 180 : 0))
            }

            if isSpecialThanksExpanded {
                VStack(spacing: 9) {
                    ForEach(["Deadpan", "Tikkuu", "竹子"], id: \.self) { name in
                        HStack(spacing: 11) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(heartGradient)

                            Text(name)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.94))

                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .background {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(red: 1.0, green: 0.30, blue: 0.46).opacity(0.10))
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Color(red: 1.0, green: 0.42, blue: 0.56).opacity(0.20), lineWidth: 0.8)
                        }
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(18)
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .onTapGesture {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.84)) {
                isSpecialThanksExpanded.toggle()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            Color.clear
                .glassCard(cornerRadius: 24, tintColor: Color(red: 1.0, green: 0.30, blue: 0.46).opacity(0.12))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.46, blue: 0.58).opacity(0.30),
                            Color(red: 1.0, green: 0.30, blue: 0.46).opacity(0.12),
                            Color.white.opacity(0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
        }
    }

    private var platformList: some View {
        VStack(spacing: 12) {
            AcknowledgementPlatformCard(
                imageName: "XiaohongshuIcon",
                platform: L("acknowledgements.platform.xiaohongshu"),
                names: ["Zestor", "有有"],
                description:"",
                accent: Color(red: 1.0, green: 0.18, blue: 0.30),
                iconStyle: .fullBleed
            )

            AcknowledgementPlatformCard(
                imageName: "XiaoheiheIcon",
                platform:L("acknowledgements.platform.xiaoheihe"),
                names: ["Sekai", "米子哈qwq", "ikuyooo", "CasperMoller", "Crbon666", "左转直飞NX", "DoubleTian", "双蛋烤冷面", "林野Linye"],
                accent: Color(red: 0.74, green: 0.80, blue: 0.88)
            )
        }
    }

    private var closingCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "bubble.left.and.text.bubble.right.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.78))
                    .frame(width: 34, height: 34)
                    .background {
                        Circle()
                            .fill(Color.white.opacity(0.11))
                    }

                Text(L("acknowledgements.closing.title"))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.90))

                Spacer(minLength: 0)
            }

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.03),
                            Color.white.opacity(0.16),
                            Color.white.opacity(0.03)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            Text(L("acknowledgements.closing.body"))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.68))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                if let url = URL(string: xiaohongshuProfileURL) {
                    openURL(url)
                }
            } label: {
                HStack(spacing: 10) {
                    Image("XiaohongshuIcon")
                        .renderingMode(.original)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    Text(L("acknowledgements.closing.button"))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Spacer(minLength: 0)

                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white.opacity(0.84))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(red: 1.0, green: 0.18, blue: 0.30).opacity(0.82))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.22), lineWidth: 0.8)
                }
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            Color.clear
                .glassCard(cornerRadius: 22, tintColor: Color.white.opacity(0.08))
        }
        .overlay(alignment: .bottomTrailing) {
            Image(systemName: "paperplane.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(Color.white.opacity(0.07))
                .padding(18)
        }
    }
}

private enum PlatformIconStyle {
    case original
    /// Artwork that is itself a finished app icon and should fill the tile edge-to-edge.
    case fullBleed
}

private struct HeaderIcon: View {
    let imageName: String
    var size: CGFloat = 58
    var padding: CGFloat = 10
    var cornerRadius: CGFloat = 18
    /// When true the artwork already includes its own background/shape and fills
    /// the tile edge-to-edge (e.g. a real app icon) instead of sitting on a white plate.
    var fullBleed: Bool = false

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(fullBleed ? Color.clear : Color.white)
            .frame(width: size, height: size)
            .overlay {
                Image(imageName)
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    // The app-icon artwork carries a transparent safe-area margin;
                    // scale it out so the icon fills the tile and shares the same
                    // rounded-corner clip as the other tiles.
                    .scaleEffect(fullBleed ? 1024.0 / 896.0 : 1.0)
                    .padding(fullBleed ? 0 : padding)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: Color.black.opacity(0.22), radius: 18, x: 0, y: 10)
    }
}

private struct AcknowledgementPlatformCard: View {
    let imageName: String
    let platform: String
    let names: [String]
    var description: String = ""
    let accent: Color
    var iconStyle: PlatformIconStyle = .original

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 14) {
                platformIcon

                VStack(alignment: .leading, spacing: 3) {
                    Text(platform)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.94))

                    if !description.isEmpty {
                        Text(description)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.56))
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)

                Text("\(names.count)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.82))
                    .frame(minWidth: 26, minHeight: 26)
                    .padding(.horizontal, 6)
                    .background {
                        Capsule()
                            .fill(accent.opacity(0.22))
                    }
                    .overlay {
                        Capsule()
                            .strokeBorder(accent.opacity(0.34), lineWidth: 0.8)
                    }
            }

            FlowLayout(spacing: 8, rowSpacing: 8) {
                ForEach(names, id: \.self) { name in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(accent.opacity(0.85))
                            .frame(width: 5, height: 5)

                        Text(name)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.90))
                    }
                    .padding(.leading, 11)
                    .padding(.trailing, 13)
                    .padding(.vertical, 7)
                    .background {
                        Capsule()
                            .fill(accent.opacity(0.16))
                    }
                    .overlay {
                        Capsule()
                            .strokeBorder(accent.opacity(0.28), lineWidth: 0.8)
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            Color.clear
                .glassCard(cornerRadius: 22, tintColor: accent.opacity(0.14))
        }
    }

    @ViewBuilder
    private var platformIcon: some View {
        switch iconStyle {
        case .fullBleed:
            Image(imageName)
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                // Scale out the artwork's transparent safe-area margin so it fills
                // the tile and shares the same rounded-corner clip.
                .scaleEffect(1024.0 / 896.0)
                .frame(width: 54, height: 54)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: accent.opacity(0.22), radius: 16, x: 0, y: 8)
        case .original:
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white)
                .frame(width: 54, height: 54)
                .overlay {
                    Image(imageName)
                        .renderingMode(.original)
                        .resizable()
                        .scaledToFit()
                        .padding(10)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.30), lineWidth: 0.8)
                }
                .shadow(color: accent.opacity(0.22), radius: 16, x: 0, y: 8)
        }
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var rowSpacing: CGFloat = 8

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let proposedWidth = proposal.width
        let maxWidth = proposedWidth ?? .greatestFiniteMagnitude
        var currentX: CGFloat = 0
        var currentRowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var widestRow: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX > 0, currentX + spacing + size.width > maxWidth {
                totalHeight += currentRowHeight + rowSpacing
                widestRow = max(widestRow, currentX)
                currentX = 0
                currentRowHeight = 0
            }

            if currentX > 0 {
                currentX += spacing
            }
            currentX += size.width
            currentRowHeight = max(currentRowHeight, size.height)
        }

        totalHeight += currentRowHeight
        widestRow = max(widestRow, currentX)
        return CGSize(width: proposedWidth ?? widestRow, height: totalHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var currentRowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX > bounds.minX, currentX + spacing + size.width > bounds.maxX {
                currentX = bounds.minX
                currentY += currentRowHeight + rowSpacing
                currentRowHeight = 0
            }

            if currentX > bounds.minX {
                currentX += spacing
            }

            subview.place(
                at: CGPoint(x: currentX, y: currentY),
                proposal: ProposedViewSize(size)
            )
            currentX += size.width
            currentRowHeight = max(currentRowHeight, size.height)
        }
    }
}

#Preview {
    AcknowledgementsView()
}
