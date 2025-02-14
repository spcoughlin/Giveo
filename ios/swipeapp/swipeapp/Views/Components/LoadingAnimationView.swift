//
//  LoadingAnimationView.swift
//  swipeapp
//
//  Created by Alec Agayan on 2/4/25.
//

import SwiftUI

struct LoadingAnimationView: View {
    @State private var isAnimating: Bool = false

    var body: some View {
        VStack {
            Spacer()
            // The rotating circle
            ZStack {
                Circle()
                    .stroke(lineWidth: 8)
                    .opacity(0.3)
                    .foregroundColor(.accentColor)
                    .frame(width: 60, height: 60)
                Circle()
                    .trim(from: 0, to: 0.6)
                    .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .foregroundColor(.accentColor)
                    .frame(width: 60, height: 60)
                    .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                    .animation(Animation.linear(duration: 2.5)
                                .repeatForever(autoreverses: false),
                               value: isAnimating)
            }
            .padding(.bottom, 10)
            
            // A descriptive label
            Text("Loading more organizations...")
                .font(.headline)
                .foregroundColor(.gray)
            Spacer()
        }
        .onAppear {
            self.isAnimating = true
        }
    }
}

#Preview {
    LoadingAnimationView()
}
