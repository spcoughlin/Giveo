//
//  UserProfileView.swift
//  HackNYU2025
//
//  Created by Alec Agayan on 2/9/25
//

import SwiftUI
import FirebaseAuth

struct UserProfileView: View {
    @EnvironmentObject var userSettings: UserSettings
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var donationManager: DonationManager  // Inject DonationManager
    
    @State private var followers: Int = 120
    @State private var following: Int = 75
    @State private var ratings: Int = 45
    
    // State to control presentation of the edit view.
    @State private var showEditProfile: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                
                // MARK: - User Info Section
                VStack(spacing: 8) {
                    ProfileImageView(profileImageURL: userViewModel.currentUser?.profileImageURL)
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(Color.accentColor, lineWidth: 2)
                        )
                        .shadow(radius: 4)
                    
                    if let user = userViewModel.currentUser {
                        Text(user.name)
                            .font(.sourceSerifPro(size: 24, weight: .semibold))
                    } else {
                        Text("User Name")
                            .font(.sourceSerifPro(size: 24, weight: .semibold))
                            .foregroundColor(.gray)
                    }
                    
                    Text("Top Donator")
                        .font(.sourceSerifPro(size: 14, weight: .semibold))
                        .foregroundColor(.gray)
                }
                .padding(.top, 16)
                
                // MARK: - Stats Row
                HStack(spacing: 40) {
                    statItem(value: followers, label: "Followers")
                    statItem(value: following, label: "Following")
                    statItem(value: ratings, label: "Donations")
                }
                .padding(.top, 8)
                
                // MARK: - My Donations
                VStack(alignment: .leading, spacing: 8) {
                    Text("My Donations")
                        .font(.sourceSerifPro(size: 18, weight: .semibold))
                        .padding(.horizontal)
                    
                    if donationManager.isLoading {
                        ProgressView()
                            .padding()
                    } else if donationManager.donations.isEmpty {
                        Text("No donations yet.")
                            .font(.sourceSerifPro(size: 16, weight: .regular))
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(donationManager.donations) { donation in
                                DonationRowView(
                                    donation: donation,
                                    isShinyNumbersEnabled: userSettings.isShinyNumbersEnabled
                                )
                            }
                        }
                        .padding(.bottom, 16)
                    }
                }
            }
        }
        .navigationTitle("Profile")
        .onAppear {
            // Fetch the current user's donations when the view appears.
            if let uid = Auth.auth().currentUser?.uid {
                donationManager.fetchDonations(for: uid)
            }
        }
        .sheet(isPresented: $showEditProfile) {
            // Replace with your actual edit profile view.
            Text("Edit User Profile View")
                .font(.sourceSerifPro(size: 24, weight: .semibold))
        }
    }
    
    @ViewBuilder
    private func statItem(value: Int, label: String) -> some View {
        VStack {
            Text("\(value)")
                .font(.sourceSerifPro(size: 20, weight: .semibold))
            Text(label)
                .font(.sourceSerifPro(size: 12, weight: .regular))
                .foregroundColor(.gray)
        }
    }
}

struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        UserProfileViewPreview()
    }
}

struct UserProfileViewPreview: View {
    @StateObject var mockUserViewModel: UserViewModel
    
    init() {
        let viewModel = UserViewModel()
        viewModel.currentUser = User(
            id: "MPqn1nqZ2sYxKcLcsA9mp34Gg272",
            name: "John Doe",
            email: "john@example.com",
            phoneNumber: "123-456-7890",
            charityID: nil,
            profileImageURL: "https://via.placeholder.com/150"
        )
        _mockUserViewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        UserProfileView()
            .environmentObject(UserSettings())
            .environmentObject(mockUserViewModel)
            .environmentObject(DonationManager())
    }
}

// MARK: - ProfileImageView

/// A reusable view to display the profile image.
/// It handles loading, success, and failure states.
struct ProfileImageView: View {
    let profileImageURL: String?
    
    var body: some View {
        if let urlString = profileImageURL,
           let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 100, height: 100)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                case .failure:
                    Image(systemName: "person.crop.circle.badge.exclamationmark")
                        .resizable()
                        .scaledToFill()
                        .foregroundColor(.gray)
                        .frame(width: 100, height: 100)
                @unknown default:
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFill()
                        .foregroundColor(.gray)
                        .frame(width: 100, height: 100)
                }
            }
        } else {
            // Default Placeholder Image
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .scaledToFill()
                .foregroundColor(.gray)
                .frame(width: 100, height: 100)
        }
    }
}
