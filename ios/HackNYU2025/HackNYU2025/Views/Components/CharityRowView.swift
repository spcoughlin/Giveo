//
//  CharityRowView.swift
//  HackNYU2025
//
//  Created by Alec Agayan on 2/9/25
//

import SwiftUI

struct CharityRowView: View {
    @ObservedObject var charity: Charity  // Observe the charity for changes

    var body: some View {
        HStack(spacing: 12) {
            // Charity Hero Image
            if let heroUIImage = charity.heroImage {
                Image(uiImage: heroUIImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.accentColor, lineWidth: 2)
                    )
                    .shadow(radius: 4)
            } else {
                // Placeholder Image
                Image(systemName: "photo.fill")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.gray)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.accentColor, lineWidth: 2)
                    )
                    .shadow(radius: 4)
            }
            
            // Charity Info
            VStack(alignment: .leading, spacing: 4) {
                Text(charity.name)
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundColor(.primary)
                
                Text(charity.description)
                    .font(.system(size: 12, weight: .regular, design: .serif))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct CharityRowView_Previews: PreviewProvider {
    static var previews: some View {
        CharityRowView(
            charity: Charity(
                //id: "1",
                name: "Clean Water Fund",
                description: "Providing clean and safe drinking water to communities in need.",
                location: "true",
                heroImageURL: "https://via.placeholder.com/150",
                logoImageURL: "https://via.placeholder.com/50"//,
                //heroImage: UIImage(systemName: "photo.fill"),
                //logoImage: UIImage(systemName: "photo.fill")
            )
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
