//
//  ImpactArticleBigCardView.swift
//  HackNYU2025
//
//  Created by Alec Agayan on 2/9/25
//

import SwiftUI

struct ImpactArticleBigCardView: View {
    var article: ImpactArticle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top image.
            Image(article.thumbnailImageName)
                .resizable()
                .scaledToFill()
                .frame(height: 200)
                .clipped()
            
            // Text content below the image.
            VStack(alignment: .leading, spacing: 4) {
                Text(article.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                Text(article.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 4)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct ImpactArticleBigCardView_Previews: PreviewProvider {
    static var previews: some View {
        ImpactArticleBigCardView(article: ImpactArticle(
            title: "Community Meal Brings Neighbors Together",
            subtitle: "A heartwarming story of unity and support.",
            thumbnailImageName: "storyPlaceholder",
            blocks: [
                ArticleBlock(type: .text("**Breaking News:** Today, the community gathered for a meal.")),
                ArticleBlock(type: .image(name: "communityMeal", caption: "Residents enjoying a shared meal."))
            ]
        ))
        .previewLayout(.sizeThatFits)
    }
}
