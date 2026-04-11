//
//  AppleWeatherAttributionView.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/4/9.
//

import SwiftUI

struct AppleWeatherAttributionView: View {
    private static let legalAttributionURL = URL(string: "https://weatherkit.apple.com/legal-attribution.html")!

    let textColor: Color
    let secondaryColor: Color
    let fontSize: CGFloat

    init(textColor: Color, secondaryColor: Color, fontSize: CGFloat = 11) {
        self.textColor = textColor
        self.secondaryColor = secondaryColor
        self.fontSize = fontSize
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(L("weather.attribution.trademark"))
                .font(.system(size: fontSize, weight: .semibold))
                .foregroundColor(textColor.opacity(0.9))
                .lineLimit(1)

            Spacer(minLength: 8)

            Link(destination: Self.legalAttributionURL) {
                Text(L("weather.attribution.link"))
                    .font(.system(size: fontSize, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .minimumScaleFactor(0.85)
            }
            .foregroundColor(secondaryColor.opacity(0.95))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(L("weather.attribution.trademark")), \(L("weather.attribution.link"))")
    }
}
