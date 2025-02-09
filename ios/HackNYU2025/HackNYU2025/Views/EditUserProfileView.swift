//
//  EditUserProfileView.swift
//  HackNYU2025
//
//  Created by Alec Agayan on 2/9/25
//

import SwiftUI
import FirebaseAuth

struct EditUserProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var userViewModel: UserViewModel

    // Local state for edited fields.
    @State private var editedName: String = ""
    @State private var editedEmail: String = ""
    @State private var newProfileImage: UIImage? = nil

    // State to control presentation of the image picker.
    @State private var showingImagePicker: Bool = false

    var body: some View {
        NavigationView {
            Form {
                // MARK: - Profile Picture Section
                Section(header: Text("Profile Picture")) {
                    HStack(spacing: 16) {
                        if let newProfileImage = newProfileImage {
                            Image(uiImage: newProfileImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                        } else if let urlString = userViewModel.currentUser?.profileImageURL,
                                  let url = URL(string: urlString) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(width: 80, height: 80)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(Circle())
                                case .failure:
                                    Image(systemName: "person.crop.circle.badge.exclamationmark")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(Circle())
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                        }
                        
                        Button("Change Photo") {
                            showingImagePicker = true
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // MARK: - Personal Information Section
                Section(header: Text("Personal Information")) {
                    TextField("Name", text: $editedName)
                        .autocapitalization(.words)
                    
                    // Typically the email is not editable, so we disable editing.
                    TextField("Email", text: $editedEmail)
                        .disabled(true)
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    updateProfile()
                }
            )
            .onAppear {
                // Populate the fields with the current user's information.
                if let user = userViewModel.currentUser {
                    editedName = user.name
                    editedEmail = user.email
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                // Your ImagePicker implementation should update newProfileImage.
                ImagePicker(image: $newProfileImage)
            }
        }
    }
    
    private func updateProfile() {
        // Call your UserViewModel update method.
        userViewModel.updateUserProfile(name: editedName, newProfileImage: newProfileImage) { success in
            if success {
                print("User profile updated successfully.")
                presentationMode.wrappedValue.dismiss()
            } else {
                print("Error updating user profile.")
                // Optionally, present an alert here.
            }
        }
    }
}

struct EditUserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock UserViewModel for preview purposes.
        let viewModel = UserViewModel()
        viewModel.currentUser = User(
            id: "exampleUserID",
            name: "John Doe",
            email: "john@example.com",
            phoneNumber: "123-456-7890",
            charityID: nil,
            profileImageURL: "https://via.placeholder.com/150"
        )
        return EditUserProfileView()
            .environmentObject(viewModel)
    }
}
