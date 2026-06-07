//
//  ImageProcessing.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/8.
//

import UIKit
import ImageIO

enum ImageProcessing {
    private static let avatarCache = NSCache<NSString, UIImage>()

    static func avatarJPEGData(
        from sourceData: Data,
        targetSide: CGFloat = 256,
        compressionQuality: CGFloat = 0.82
    ) -> Data? {
        guard let sourceImage = downsampledImage(from: sourceData, maxPixelSize: max(targetSide * 2, 640)) else {
            return nil
        }
        let squareSize = CGSize(width: targetSide, height: targetSide)
        let renderer = UIGraphicsImageRenderer(size: squareSize)

        let image = renderer.image { context in
            let srcSize = sourceImage.size
            let scale = max(squareSize.width / srcSize.width, squareSize.height / srcSize.height)
            let drawSize = CGSize(width: srcSize.width * scale, height: srcSize.height * scale)
            let origin = CGPoint(
                x: (squareSize.width - drawSize.width) * 0.5,
                y: (squareSize.height - drawSize.height) * 0.5
            )
            sourceImage.draw(in: CGRect(origin: origin, size: drawSize))
        }

        return image.jpegData(compressionQuality: compressionQuality)
    }

    static func avatarImage(from data: Data, cacheKey: String) -> UIImage? {
        let key = cacheKey as NSString
        if let cached = avatarCache.object(forKey: key) {
            return cached
        }
        guard let image = UIImage(data: data) else { return nil }
        avatarCache.setObject(image, forKey: key)
        return image
    }

    static func downsampledUIImage(from data: Data, maxPixelSize: CGFloat) -> UIImage? {
        downsampledImage(from: data, maxPixelSize: maxPixelSize)
    }

    private static func downsampledImage(from data: Data, maxPixelSize: CGFloat) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }

        let options: CFDictionary = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: Int(maxPixelSize),
            kCGImageSourceShouldCacheImmediately: true
        ] as CFDictionary

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}
