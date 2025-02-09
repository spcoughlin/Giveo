//
//  CharityImageView.swift
//  HackNYU2025
//
//  Created by Alec Agayan on 2/9/25
//

import SwiftUI

struct CharityImageView: View {
    let imageURL: String?
    let placeholderSystemName: String
    let contentMode: ContentMode
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    
    init(
        imageURL: String?,
        placeholderSystemName: String = "photo.fill",
        contentMode: ContentMode = .fill,
        width: CGFloat = 60,
        height: CGFloat = 60,
        cornerRadius: CGFloat = 8
    ) {
        self.imageURL = imageURL
        self.placeholderSystemName = placeholderSystemName
        self.contentMode = contentMode
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        if let urlString = imageURL,
           let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: width, height: height)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(cornerRadius)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                        .frame(width: width, height: height)
                        .clipped()
                        .cornerRadius(cornerRadius)
                case .failure:
                    Image(systemName: placeholderSystemName)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.gray)
                        .frame(width: width, height: height)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(cornerRadius)
                @unknown default:
                    Image(systemName: placeholderSystemName)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.gray)
                        .frame(width: width, height: height)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(cornerRadius)
                }
            }
        } else {
            // Default Placeholder Image
            Image(systemName: placeholderSystemName)
                .resizable()
                .scaledToFit()
                .foregroundColor(.gray)
                .frame(width: width, height: height)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(cornerRadius)
        }
    }
}

struct CharityImageView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Preview with a valid image URL
            CharityImageView(
                imageURL: "https://via.placeholder.com/150",
                placeholderSystemName: "photo.fill",
                contentMode: .fill,
                width: 100,
                height: 100,
                cornerRadius: 12
            )
            .previewLayout(.sizeThatFits)
            .padding()
            
            // Preview with an invalid image URL
            CharityImageView(
                imageURL: "invalid_url",
                placeholderSystemName: "photo.fill",
                contentMode: .fill,
                width: 100,
                height: 100,
                cornerRadius: 12
            )
            .previewLayout(.sizeThatFits)
            .padding()
            
            // Preview with no image URL
            CharityImageView(
                imageURL: nil,
                placeholderSystemName: "photo.fill",
                contentMode: .fill,
                width: 100,
                height: 100,
                cornerRadius: 12
            )
            .previewLayout(.sizeThatFits)
            .padding()
        }
    }
}
