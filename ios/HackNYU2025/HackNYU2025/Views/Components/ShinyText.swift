//
//  ShinyText.swift
//  HackNYU2025
//
//  Created by Alec Agayan on 2/9/25
//

import SwiftUI

struct ShinyText: View {
    let text: String
    let font: Font
    let weight: Font.Weight

    @ObservedObject var motion = MotionManager()  // from the previous example

    var body: some View {
        // Use accelerometer data to shift the gradient slightly.
        // Tweak these scales to taste:
        let offsetX = motion.xAccel * 0.5
        let offsetY = motion.yAccel * 0.5

        // Metallic/silver gradient: a few grayscale stops
        let metallicSilverGradient = LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color(white: 0.8),  location: 0.0),
                .init(color: Color(white: 0.95), location: 0.2),
                .init(color: Color(white: 0.6),  location: 0.4),
                .init(color: Color(white: 0.95), location: 0.7),
                .init(color: Color(white: 0.8),  location: 1.0)
            ]),
            startPoint: UnitPoint(x: 0.5 + offsetX, y: 0.0 + offsetY),
            endPoint:   UnitPoint(x: 1.0 + offsetX, y: 1.0 + offsetY)
        )

        let baseText = Text(text)
            .font(font)
            .fontWeight(weight)
        
        return baseText
            // Overlay the gradient, then mask it to the shape of the text
            .overlay(
                metallicSilverGradient
                    .mask(baseText)
            )
    }
}
