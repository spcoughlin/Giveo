//
//  CharityCardView.swift
//  HackNYU2025
//
//  Created by Alec Agayan on 2/9/25
//

import SwiftUI

struct CharityCardView: View {
    @ObservedObject var charity: Charity
    let onSwipe: (SwipeDirection) -> Void
    let namespace: Namespace.ID

    @State private var offset: CGSize = .zero
    @GestureState private var isDragging = false
    @State private var hasSwipedOut = false
    @State private var isSaving: Bool = false
    @State private var isShowingDetail = false

    var body: some View {
        Group {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .shadow(radius: 4)
                
                GeometryReader { geo in
                    let totalWidth = geo.size.width
                    let totalHeight = geo.size.height
                    
                    if let heroUIImage = charity.heroImage, let logoUIImage = charity.logoImage {
                        Image(uiImage: heroUIImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: totalWidth, height: totalHeight)
                            .clipped()
                            .overlay(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.8)]),
                                    startPoint: UnitPoint(x: 0.5, y: 0.6),
                                    endPoint: .bottom
                                )
                            )
                            .overlay(
                                Image(uiImage: logoUIImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40, height: 40)
                                    .padding(8),
                                alignment: .topLeading
                            )
                            .overlay(
                                VStack(alignment: .leading, spacing: 4) {
                                    Spacer()
                                    Text(charity.name)
                                        .font(.custom("SourceSerifPro-Semibold", size: 20))
                                        .foregroundColor(.white)
                                    Text(charity.description)
                                        .font(.custom("SourceSerifPro-Regular", size: 16))
                                        .foregroundColor(Color.white.opacity(0.8))
                                        .lineLimit(2)
                                        .truncationMode(.tail)
                                }
                                .padding()
                                .frame(width: totalWidth, alignment: .leading)
                            )
                    } else {
                        Image("whitehouseHero")
                            .resizable()
                            .scaledToFill()
                            .frame(width: totalWidth, height: totalHeight)
                            .foregroundColor(.gray)
                            .background(Color.gray.opacity(0.1))
                            .clipped()
                            .overlay(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.8)]),
                                    startPoint: UnitPoint(x: 0.5, y: 0.6),
                                    endPoint: .bottom
                                )
                            )
                            .overlay(
                                VStack(alignment: .leading, spacing: 4) {
                                    Spacer()
                                    Text(charity.name)
                                        .font(.custom("SourceSerifPro-Semibold", size: 20))
                                        .foregroundColor(.white)
                                    Text(charity.description)
                                        .font(.custom("SourceSerifPro-Regular", size: 16))
                                        .foregroundColor(Color.white.opacity(0.8))
                                        .lineLimit(2)
                                        .truncationMode(.tail)
                                }
                                .padding()
                                .frame(width: totalWidth, alignment: .leading)
                            )
                    }
                }
                
                if let tags = charity.primaryTags, !tags.isEmpty {
                    TagsVerticalView(tags: tags)
                        .padding(8)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(4/5, contentMode: .fit)
        .cornerRadius(12)
        .offset(x: offset.width, y: offset.height * 0.2)
        .rotationEffect(.degrees(Double(offset.width / 20)))
        .matchedGeometryEffect(id: isSaving ? "saveButton" : "card\(charity.id)", in: namespace)
        .gesture(
            DragGesture()
                .updating($isDragging) { _, state, _ in
                    state = true
                }
                .onChanged { gesture in
                    offset = gesture.translation
                }
                .onEnded { gesture in
                    guard !hasSwipedOut else { return }
                    
                    let dx = gesture.translation.width
                    let dy = gesture.translation.height
                    
                    if abs(dx) > abs(dy) {
                        if dx > 100 {
                            swipeOut(direction: .right)
                        } else if dx < -100 {
                            swipeOut(direction: .left)
                        } else {
                            snapBack()
                        }
                    } else {
                        if dy < -100 {
                            swipeUpToDetail()
                        } else if dy > 100 {
                            // Instead of doing fancy animations for swipe down,
                            // we simply call onSwipe with .down immediately.
                            onSwipe(.down)
                        } else {
                            snapBack()
                        }
                    }
                }
        )
        .animation(isDragging ? nil : .spring(), value: offset)
        .sheet(isPresented: $isShowingDetail) {
            NavigationView {
                CharityDetailView(charity: charity)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func swipeOut(direction: SwipeDirection) {
        if direction == .down { return }
        withAnimation(.easeIn(duration: 0.3)) {
            switch direction {
            case .left:
                offset = CGSize(width: -1000, height: 0)
            case .right:
                offset = CGSize(width: 1000, height: 0)
            default:
                break
            }
        }
        onSwipe(direction)
    }
    
    private func snapBack() {
        withAnimation(.spring()) {
            offset = .zero
        }
    }
    
    private func swipeUpToDetail() {
        snapBack()
        isShowingDetail = true
    }
}

// MARK: - TagsVerticalView (unchanged)
struct TagsVerticalView: View {
    let tags: [String]
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption2)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color.black.opacity(0.6))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }
    }
}

// MARK: - Preview
struct CharityCard_Previews: PreviewProvider {
    @Namespace static var previewNamespace
    
    static var previews: some View {
        Group {
            let foodBankCharity = Charity(
                id: "1",
                name: "Food Bank",
                description: "Providing food assistance to those in need. This is a long description that should be truncated after two lines so that only a preview of the text is visible.",
                location: "true",
                heroImageURL: "foodbankHero",
                logoImageURL: "foodbankLogo",
                primaryTags: ["Food", "Community", "Health"]
            )
            
            CharityCardView(
                charity: foodBankCharity,
                onSwipe: { direction in
                    print("Swiped \(direction)")
                },
                namespace: previewNamespace
            )
            .previewDisplayName("With Food Bank Images")
            .padding()
        }
        .previewLayout(.sizeThatFits)
    }
}
