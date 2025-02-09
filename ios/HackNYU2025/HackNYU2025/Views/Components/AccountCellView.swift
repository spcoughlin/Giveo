//
//  AccountCellView.swift
//  HackNYU2025
//
//  Created by Alec Agayan on 2/9/25
//

import SwiftUI

struct AccountCellView: View {
    var user: User

    var body: some View {
        HStack {
            // Profile Image
            if let urlString = user.profileImageURL,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        // Placeholder while loading
                        ProgressView()
                            .frame(width: 50, height: 50)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    case .failure:
                        // Error placeholder
                        Image(systemName: "person.crop.circle.badge.exclamationmark")
                            .resizable()
                            .foregroundColor(.gray)
                            .frame(width: 50, height: 50)
                    @unknown default:
                        // Fallback placeholder
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .foregroundColor(.gray)
                            .frame(width: 50, height: 50)
                    }
                }
            } else {
                // Default Placeholder Image
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .foregroundColor(.gray)
                    .frame(width: 50, height: 50)
            }

            // User Name and Email
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.headline)
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.leading, 8)

            Spacer()

            // Navigation Indicator
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
}

struct AccountCellView_Previews: PreviewProvider {
    static var previews: some View {
        AccountCellView(user: User(
            id: "12345",
            name: "Jane Smith",
            email: "jane@example.com",
            phoneNumber: "987-654-3210",
            charityID: nil,
            profileImageURL: "https://example.com/profile.jpg"
        ))
        .previewLayout(.sizeThatFits)
    }
}
