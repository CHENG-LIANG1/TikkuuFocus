//
//  TransportAvatarView.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/8.
//

import SwiftUI
import UIKit

struct TransportAvatarView: View {
    let defaultSymbolName: String
    let settings: TransportAvatarSettings?
    let size: CGFloat
    let symbolSize: CGFloat
    let symbolWeight: Font.Weight
    let symbolColor: Color
    let borderColor: Color?
    let borderWidth: CGFloat

    init(
        defaultSymbolName: String,
        settings: TransportAvatarSettings?,
        size: CGFloat,
        symbolSize: CGFloat,
        symbolWeight: Font.Weight,
        symbolColor: Color,
        borderColor: Color? = nil,
        borderWidth: CGFloat = 0
    ) {
        self.defaultSymbolName = defaultSymbolName
        self.settings = settings
        self.size = size
        self.symbolSize = symbolSize
        self.symbolWeight = symbolWeight
        self.symbolColor = symbolColor
        self.borderColor = borderColor
        self.borderWidth = borderWidth
    }

    var body: some View {
        if let image = resolvedImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay {
                    if let borderColor, borderWidth > 0 {
                        Circle()
                            .stroke(borderColor, lineWidth: borderWidth)
                    }
                }
        } else {
            Image(systemName: defaultSymbolName)
                .font(.system(size: symbolSize, weight: symbolWeight))
                .foregroundColor(symbolColor)
                .frame(width: size, height: size)
        }
    }

    private var resolvedImage: UIImage? {
        guard settings?.isEnabled == true,
              let settings,
              let data = settings.imageData else {
            return nil
        }
        let key = "transport-avatar-\(settings.id.uuidString)-\(settings.updatedAt.timeIntervalSince1970)-\(data.count)"
        return ImageProcessing.avatarImage(from: data, cacheKey: key)
    }
}
