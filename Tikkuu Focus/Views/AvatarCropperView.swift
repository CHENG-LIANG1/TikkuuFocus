//
//  AvatarCropperView.swift
//  Tikkuu Focus
//

import SwiftUI
import UIKit

struct AvatarCropperView: View {
    let image: UIImage
    let targetSide: CGFloat
    let compressionQuality: CGFloat
    let onComplete: (Data?) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 20) {
                    GeometryReader { geo in
                        let side = min(geo.size.width, geo.size.height)

                        ZStack {
                            Color.black

                            cropImage(side: side)
                                .gesture(dragGesture(side: side))
                                .gesture(zoomGesture(side: side))

                            if shouldShowRecenter {
                                VStack {
                                    Spacer()

                                    Button(L("settings.avatar.crop.recenter")) {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                            scale = 1.0
                                            lastScale = 1.0
                                            offset = .zero
                                            lastOffset = .zero
                                        }
                                    }
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(
                                        Capsule(style: .continuous)
                                            .fill(Color.white.opacity(0.12))
                                            .overlay(
                                                Capsule(style: .continuous)
                                                    .stroke(Color.white.opacity(0.22), lineWidth: 1)
                                            )
                                    )
                                    .buttonStyle(.plain)
                                }
                                .padding(.bottom, 12)
                            }
                        }
                        .frame(width: side, height: side)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.white.opacity(0.25), lineWidth: 1)
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle(L("settings.avatar.crop.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L("common.cancel")) {
                        dismiss()
                        onComplete(nil)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L("common.done")) {
                        onComplete(renderCroppedJPEG())
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            scale = 1.0
            lastScale = 1.0
            offset = .zero
            lastOffset = .zero
        }
    }

    private func cropImage(side: CGFloat) -> some View {
        let base = baseDraw(side: side)
        return Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: base.size.width, height: base.size.height)
            .scaleEffect(scale)
            .offset(x: offset.width, y: offset.height)
            .position(x: side * 0.5, y: side * 0.5)
            .frame(width: side, height: side)
            .clipped()
    }

    private func baseDraw(side: CGFloat) -> (origin: CGPoint, size: CGSize) {
        let src = image.size
        let baseScale = max(side / src.width, side / src.height)
        let drawSize = CGSize(width: src.width * baseScale, height: src.height * baseScale)
        let origin = CGPoint(
            x: (side - drawSize.width) * 0.5,
            y: (side - drawSize.height) * 0.5
        )
        return (origin, drawSize)
    }

    private func clampOffset(_ proposed: CGSize, side: CGFloat) -> CGSize {
        let base = baseDraw(side: side)
        let scaledSize = CGSize(width: base.size.width * scale, height: base.size.height * scale)
        let maxX = max(0, (scaledSize.width - side) * 0.5)
        let maxY = max(0, (scaledSize.height - side) * 0.5)

        return CGSize(
            width: min(max(proposed.width, -maxX), maxX),
            height: min(max(proposed.height, -maxY), maxY)
        )
    }

    private func zoomGesture(side: CGFloat) -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let newScale = min(max(lastScale * value, 1.0), 4.0)
                scale = newScale
                offset = clampOffset(offset, side: side)
            }
            .onEnded { _ in
                lastScale = scale
                offset = clampOffset(offset, side: side)
                lastOffset = offset
            }
    }

    private func dragGesture(side: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let proposed = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
                offset = clampOffset(proposed, side: side)
            }
            .onEnded { _ in
                offset = clampOffset(offset, side: side)
                lastOffset = offset
            }
    }

    private func renderCroppedJPEG() -> Data? {
        let side: CGFloat = targetSide
        let base = baseDraw(side: side)

        let scaledSize = CGSize(width: base.size.width * scale, height: base.size.height * scale)
        let scaledOrigin = CGPoint(
            x: (side * 0.5) + offset.width - (scaledSize.width * 0.5),
            y: (side * 0.5) + offset.height - (scaledSize.height * 0.5)
        )

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side))
        let rendered = renderer.image { _ in
            image.draw(in: CGRect(origin: scaledOrigin, size: scaledSize))
        }

        return rendered.jpegData(compressionQuality: compressionQuality)
    }

    private var shouldShowRecenter: Bool {
        abs(offset.width) > 0.5 || abs(offset.height) > 0.5 || abs(scale - 1.0) > 0.01
    }
}
