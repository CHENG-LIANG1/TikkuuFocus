//
//  AppleWeatherAttributionView.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/4/9.
//

import SwiftUI
import WeatherKit

struct AppleWeatherAttributionView: View {
    private static let fallbackLegalAttributionURL = URL(string: "https://weatherkit.apple.com/legal-attribution.html")!

    let textColor: Color
    let fontSize: CGFloat
    let attribution: WeatherAttribution?

    init(
        textColor: Color,
        fontSize: CGFloat = 9,
        attribution: WeatherAttribution? = nil
    ) {
        self.textColor = textColor
        self.fontSize = fontSize
        self.attribution = attribution
    }

    @Environment(\.colorScheme) private var colorScheme

    private var legalURL: URL {
        attribution?.legalPageURL ?? Self.fallbackLegalAttributionURL
    }

    private var logoImageURL: URL? {
        guard let attribution = attribution else { return nil }
        return colorScheme == .dark ? attribution.combinedMarkDarkURL : attribution.combinedMarkLightURL
    }

    private var logoContent: some View {
        Group {
            if let url = logoImageURL {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(height: fontSize + 3) // Fine-tuned to match visual weight
                        .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                } placeholder: {
                    // Use a slightly larger font for placeholder to match image text weight
                    trademarkText(isPlaceholder: true)
                        .opacity(0)
                }
            } else {
                trademarkText(isPlaceholder: false)
            }
        }
        .frame(height: fontSize * 1.5) // Sufficient container height to prevent clipping
    }

    private func trademarkText(isPlaceholder: Bool) -> some View {
        Text(L("weather.attribution.trademark"))
            // If it's a placeholder or fallback, we use a slightly larger size (+1) 
            // to match the visual scale of the Apple logo image
            .font(.system(size: isPlaceholder ? fontSize + 1 : fontSize + 0.5, weight: .semibold, design: .default))
            .lineLimit(1)
    }

    var body: some View {
        Link(destination: legalURL) {
            HStack(spacing: 5) {
                logoContent
                
                Text("·")
                    .font(.system(size: fontSize, weight: .light))
                    .opacity(0.3)
                
                Text(L("weather.attribution.link"))
                    .font(.system(size: fontSize, weight: .regular, design: .default))
                    .lineLimit(1)
            }
            .foregroundColor(textColor.opacity(0.7))
            .padding(.vertical, 2)
        }
    }
}
