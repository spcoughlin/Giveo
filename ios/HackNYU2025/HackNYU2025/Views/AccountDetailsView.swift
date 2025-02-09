//
//  AccountDetailsView.swift
//  HackNYU2025
//
//  Created by Alec Agayan on 2/9/25
//

import SwiftUI

struct AccountDetailsView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var isEditingName: Bool = false
    @State private var newName: String = ""
    
    @State private var isEditingEmail: Bool = false
    @State private var newEmail: String = ""
    
    @State private var showImagePicker: Bool = false
    @State private var selectedImage: UIImage? = nil
    
    var body: some View {
        if let user = userViewModel.currentUser {
            Form {
                // Profile Picture Section
                Section {
                    HStack {
                        Spacer()
                        ZStack {
                            if let urlString = user.profileImageURL,
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
                                            .foregroundColor(.gray)
                                            .frame(width: 100, height: 100)
                                    @unknown default:
                                        Image(systemName: "person.crop.circle.fill")
                                            .resizable()
                                            .foregroundColor(.gray)
                                            .frame(width: 100, height: 100)
                                    }
                                }
                            } else {
                                // Default Placeholder Image
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .foregroundColor(.gray)
                                    .frame(width: 100, height: 100)
                            }
                        }
                        .onTapGesture {
                            showImagePicker = true
                        }
                        Spacer()
                    }
                    .padding(.vertical, 10)
                    
                    Text("Tap the image to change your profile picture.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                
                // Name Section
                Section(header: Text("Name")) {
                    if isEditingName {
                        TextField("Enter new name", text: $newName)
                        Button("Save") {
                            let trimmedName = newName.trimmingCharacters(in: .whitespaces)
                            guard !trimmedName.isEmpty else {
                                userViewModel.error = IdentifiableError(message: "Name cannot be empty.")
                                return
                            }
                            userViewModel.updateName(newName: trimmedName)
                            isEditingName = false
                        }
                        .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                    } else {
                        HStack {
                            Text(user.name)
                            Spacer()
                            Button("Edit") {
                                isEditingName = true
                                newName = user.name
                            }
                        }
                    }
                }
                
                // Email Section
                Section(header: Text("Email")) {
                    if isEditingEmail {
                        TextField("Enter new email", text: $newEmail)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        Button("Save") {
                            let trimmedEmail = newEmail.trimmingCharacters(in: .whitespaces)
                            guard !trimmedEmail.isEmpty else {
                                userViewModel.error = IdentifiableError(message: "Email cannot be empty.")
                                return
                            }
                            guard isValidEmail(trimmedEmail) else {
                                userViewModel.error = IdentifiableError(message: "Please enter a valid email address.")
                                return
                            }
                            userViewModel.updateEmail(newEmail: trimmedEmail)
                            isEditingEmail = false
                        }
                        .disabled(!isValidEmail(newEmail))
                    } else {
                        HStack {
                            Text(user.email)
                            Spacer()
                            Button("Edit") {
                                isEditingEmail = true
                                newEmail = user.email
                            }
                        }
                    }
                }
                
                // Add more account-related fields as needed
            }
            .navigationTitle("Account Details")
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .onChange(of: selectedImage) { newImage in
                if let image = newImage {
                    userViewModel.updateProfileImage(image: image)
                }
            }
            .overlay(
                Group {
                    if userViewModel.isUploadingImage {
                        Color.black.opacity(0.4)
                            .edgesIgnoringSafeArea(.all)
                        ProgressView("Uploading...")
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                    }
                }
            )
            .alert(item: $userViewModel.error) { error in
                Alert(
                    title: Text("Error"),
                    message: Text(error.message),
                    dismissButton: .default(Text("OK")) {
                        userViewModel.error = nil // Reset the error after dismissal
                    }
                )
            }
        } else {
            // Handle the case when user data is not loaded
            VStack {
                ProgressView("Loading...")
            }
            .navigationTitle("Account Details")
        }
    }
    
    // Email validation function
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "(?:[A-Z0-9a-z._%+-]+)@(?:[A-Za-z0-9-]+\\.)+[A-Za-z]{2,64}"
        let predicate = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return predicate.evaluate(with: email)
    }
}

struct AccountDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        let user = User(
            id: "12345",
            name: "Jane Smith",
            email: "jane@example.com",
            phoneNumber: "987-654-3210",
            charityID: nil,
            profileImageURL: nil
        )
        let userViewModel = UserViewModel()
        userViewModel.currentUser = user
        
        return AccountDetailsView()
            .environmentObject(userViewModel)
    }
}
