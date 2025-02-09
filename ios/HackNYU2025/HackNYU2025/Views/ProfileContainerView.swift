//
//  ProfileContainerView.swift
//  HackNYU2025
//
//  Created by Alec Agayan on 2/9/25
//

import SwiftUI

struct ProfileContainerView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var charitiesManager: CharitiesManager
    @EnvironmentObject var donationManager: DonationManager

    enum ProfileType: String {
        case user = "User Profile"
        case charity = "Charity Profile"
    }

    @State private var selectedProfile: ProfileType = .user
    @State private var showProfileSwitchDialog: Bool = false
    @State private var showEditProfile: Bool = false
    @State private var showAnalytics: Bool = false

    var body: some View {
        if let charityID = userViewModel.currentUser?.charityID, !charityID.isEmpty {
            ZStack(alignment: .bottomTrailing) {
                // Main scrollable content.
                ScrollView {
                    if selectedProfile == .user {
                        UserProfileView()
                    } else {
                        CharityProfileView()
                    }
                }
                
                // Floating control area.
                HStack(spacing: 8) {
                    // Edit Profile button.
                    Button(action: {
                        showEditProfile = true
                    }) {
                        Text("Edit Profile")
                            .font(.sourceSerifPro(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(height: 44)
                            .padding(.horizontal, 16)
                    }
                    .background(Color.accentColor)
                    .clipShape(Capsule())
                    .shadow(radius: 2)

                    
                    // View Analytics button (only for charity profile).
                    if selectedProfile == .charity {
                        Button(action: {
                            showAnalytics = true
                        }) {
                            Text("View Analytics")
                                .font(.sourceSerifPro(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(height: 44)
                                .padding(.horizontal, 16)
                        }
                        .background(Color.gray)
                        .clipShape(Capsule())
                        .shadow(radius: 2)

                    }
                    
                    // Profile-switch button.
                    Button(action: {
                        showProfileSwitchDialog = true
                    }) {
                        Image(systemName: "arrow.2.circlepath")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.accentColor)
                            .padding(12)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(Circle())
                            .shadow(radius: 2)
                    }
                }
                .padding(16)
                .confirmationDialog("Switch Profile", isPresented: $showProfileSwitchDialog, titleVisibility: .visible) {
                    Button("User Profile") { selectedProfile = .user }
                    Button("Charity Profile") { selectedProfile = .charity }
                    Button("Cancel", role: .cancel) { }
                }
            }
            // Edit profile sheet.
            .sheet(isPresented: $showEditProfile) {
                if selectedProfile == .user {
                    // Replace with your actual EditUserProfileView.
                    EditUserProfileView()
                        .environmentObject(userViewModel)
                } else {
                    if let charityID = userViewModel.currentUser?.charityID,
                       let charity = charitiesManager.allCharities.first(where: { $0.id == charityID }) {
                        EditCharityProfileView(charity: charity)
                            .environmentObject(charitiesManager)
                    } else {
                        Text("No charity found.")
                    }
                }
            }
            // Analytics sheet.
            .sheet(isPresented: $showAnalytics) {
                AnalyticsView()
            }
        } else {
            // If no charity is associated, simply show the UserProfileView.
            UserProfileView()
        }
    }
}

struct ProfileContainerView_Previews: PreviewProvider {
    static var previews: some View {
        // For preview purposes, create a dummy user with a charityID.
        let user = User(
            id: "user123",
            name: "Jane Smith",
            email: "jane@example.com",
            phoneNumber: "987-654-3210",
            charityID: "charity123", // Nonempty to enable switching.
            profileImageURL: "https://via.placeholder.com/150"
        )
        let userViewModel = UserViewModel()
        userViewModel.currentUser = user

        let charitiesManager = CharitiesManager()
        let donationManager = DonationManager()

        return ProfileContainerView()
            .environmentObject(userViewModel)
            .environmentObject(charitiesManager)
            .environmentObject(donationManager)
    }
}
