//
//  BookmarkShape.swift
//  swipeapp
//
//  Created by Alec Agayan on 2/8/25.
//

import SwiftUI

struct BookmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Start at the top-left corner.
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        // Draw the top edge to the top-right corner.
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        // Draw the right edge down to the bottom-right corner.
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        // Draw a line to create the "notch" at the bottom center.
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - 20))
        // Draw a line to the bottom-left corner.
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        // Close the path back to the starting point.
        path.closeSubpath()
        
        return path
    }
}

struct BookmarkShape_Previews: PreviewProvider {
    static var previews: some View {
        BookmarkShape()
            .fill(LinearGradient(
                gradient: Gradient(colors: [.blue, .purple]),
                startPoint: .top,
                endPoint: .bottom)
            )
            .frame(width: 100, height: 150)
            .padding()
    }
}
