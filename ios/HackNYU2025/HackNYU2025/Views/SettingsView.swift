//
//  SettingsView.swift
//  HackNYU2025
//
//  Created by Alec Agayan on 2/9/25
//

import SwiftUI

struct SettingsView: View {
    // Environment objects for user settings and authentication.
    @EnvironmentObject var userSettings: UserSettings
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var authViewModel: AuthViewModel

    // State to handle sign-out confirmation.
    @State private var showSignOutAlert: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                // Use a system background that adapts to light/dark mode.
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // MARK: - Account Section
                        settingsSection(content: {
                            if let user = userViewModel.currentUser {
                                NavigationLink(destination: AccountDetailsView()) {
                                    HStack(spacing: 16) {
                                        // User Avatar
                                        if let avatarURL = user.profileImageURL, let url = URL(string: avatarURL) {
                                            AsyncImage(url: url) { image in
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                            } placeholder: {
                                                ProgressView()
                                            }
                                            .frame(width: 60, height: 60)
                                            .clipShape(Circle())
                                        } else {
                                            Image(systemName: "person.circle.fill")
                                                .resizable()
                                                .foregroundColor(.gray)
                                                .frame(width: 60, height: 60)
                                        }
                                        
                                        // User Info
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(user.name)
                                                .font(.custom("SourceSerifPro-Semibold", size: 18))
                                                .foregroundColor(.primary)
                                            Text(user.email)
                                                .font(.custom("SourceSerifPro-Regular", size: 14))
                                                .foregroundColor(.gray)
                                        }
                                        Spacer()
                                    }
                                    .padding()
                                }
                            } else {
                                HStack(spacing: 16) {
                                    ProgressView()
                                    Text("Loading...")
                                        .foregroundColor(.gray)
                                        .font(.custom("SourceSerifPro-Regular", size: 16))
                                }
                                .padding()
                            }
                        }, header: {
                            Text("Account")
                                .font(.custom("SourceSerifPro-Regular", size: 16))
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        })
                        
                        // MARK: - Appearance Section
                        settingsSection(content: {
                            Toggle(isOn: $userSettings.isShinyNumbersEnabled) {
                                HStack {
                                    Image(systemName: "sparkles")
                                        .foregroundColor(.blue)
                                    Text("Shiny Numbers")
                                        .font(.custom("SourceSerifPro-Regular", size: 16))
                                        .foregroundColor(.primary)
                                }
                            }
                            .padding()
                        }, header: {
                            Text("Appearance")
                                .font(.custom("SourceSerifPro-Regular", size: 16))
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        })
                        
                        // MARK: - Charity Account Section
                        // Remove the header here so that the cell is the only label.
                        settingsSection(content: {
                            NavigationLink(destination: CharityApplicationView()) {
                                HStack {
                                    Image(systemName: "building.2.crop.circle")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 20))
                                    Text("Apply for Charity Account")
                                        .font(.custom("SourceSerifPro-Regular", size: 16))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                            }
                        })
                        
                        // MARK: - Account Actions Section
                        settingsSection(content: {
                            Button(action: {
                                showSignOutAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "arrow.backward.circle")
                                        .foregroundColor(.red)
                                        .font(.system(size: 20))
                                    Text("Log Out")
                                        .font(.custom("SourceSerifPro-Regular", size: 16))
                                        .foregroundColor(.red)
                                    Spacer()
                                }
                                .padding()
                            }
                        })
                        
                        // Footer
                        VStack(spacing: 4) {
                            Text("@ Copyright. All rights reserved.")
                                .font(.custom("SourceSerifPro-Regular", size: 12))
                                .foregroundColor(.gray)
                            Text("App Version 0.0.1")
                                .font(.custom("SourceSerifPro-Regular", size: 12))
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 16)
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .alert(isPresented: $showSignOutAlert) {
                Alert(
                    title: Text("Log Out"),
                    message: Text("Are you sure you want to log out?"),
                    primaryButton: .destructive(Text("Log Out")) {
                        authViewModel.signOut()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
}

// MARK: - Settings Section Helper

extension SettingsView {
    /// A helper view builder for creating a section with a header and a rounded background.
    private func settingsSection<Header: View, Content: View>(
        @ViewBuilder content: () -> Content,
        @ViewBuilder header: () -> Header = { Text("") }
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            header()
                .padding(.vertical, 4)
            VStack {
                content()
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            .padding(.horizontal)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(UserSettings())
            .environmentObject(UserViewModel())
            .environmentObject(AuthViewModel())
    }
}
