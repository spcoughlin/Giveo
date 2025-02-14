//
//  SignUpView.swift
//  swipeapp
//
//  Created by Alec Agayan on 1/17/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    
                    // Name Field
                    TextField("Name", text: $name)
                        .autocapitalization(.words)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                    
                    // Email Field
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                    
                    // Password Field
                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                    
                    // Confirm Password Field
                    SecureField("Confirm Password", text: $confirmPassword)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                    
                    // Show error from AuthViewModel
                    if let error = authViewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Sign Up Button
                    Button("Sign Up") {
                        // Validate input fields
                        guard !name.isEmpty else {
                            authViewModel.errorMessage = "Please enter your name."
                            return
                        }
                        guard !email.isEmpty else {
                            authViewModel.errorMessage = "Please enter your email."
                            return
                        }
                        guard password == confirmPassword else {
                            authViewModel.errorMessage = "Passwords do not match."
                            return
                        }
                        guard !password.isEmpty else {
                            authViewModel.errorMessage = "Please enter a password."
                            return
                        }
                        
                        // Sign up action
                        authViewModel.signUp(email: email, password: password, name: name)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
                    Spacer()
                }
                .padding()
                .navigationTitle("Sign Up")
            }
        }
    }
}

#Preview {
    SignUpView()
        .environmentObject(AuthViewModel())
}
