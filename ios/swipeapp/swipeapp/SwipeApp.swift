//
//  swipeappApp.swift
//  swipeapp
//
//  Created by Alec Agayan on 1/16/25.
//

import SwiftUI
import Firebase

@main
struct SwipeApp: App {
    @StateObject var authViewModel = AuthViewModel()
    @StateObject var userViewModel = UserViewModel()
    @StateObject var userSettings = UserSettings()
    @StateObject var charitiesManager = CharitiesManager()
    @StateObject var donationManager = DonationManager()

    @StateObject private var savedCharitiesManager = SavedCharitiesManager(userID: nil) // Initialize without userID
    
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                TabView {
                    SwipeView()
                        .tabItem {
                            Label("Home", systemImage: "house.fill")
                        }
//                    
//                    ImpactArticleFeedView()
//                        .tabItem {
//                            Label("Search", systemImage: "magnifyingglass")
//                        }
                    
                    SavedView()
                        .tabItem {
                            Label("Saved", systemImage: "bookmark.fill")
                        }
                    
                    // Use the new ProfileContainerView instead of conditionally selecting a view.
                    ProfileContainerView()
                        .tabItem {
                            Label("Profile", systemImage: "person.fill")
                        }
                    
                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gearshape.fill")
                        }
                }
                .environmentObject(authViewModel)
                .environmentObject(userViewModel)
                .environmentObject(userSettings)
                .environmentObject(savedCharitiesManager)
                .environmentObject(charitiesManager)
                .environmentObject(donationManager)
            } else {
                AuthView()
                    .environmentObject(authViewModel)
                    .environmentObject(savedCharitiesManager)
                    .environmentObject(charitiesManager)
            }
        }
    }
}
