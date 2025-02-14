//
//  AuthView.swift
//  swipeapp
//
//  Created by Alec Agayan on 1/17/25.
//

import SwiftUI
import AuthenticationServices
import CryptoKit
import FirebaseAuth

struct AuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.colorScheme) var colorScheme

    // Controls whether the email form is showing.
    @State private var showEmailForm: Bool = false
    // Determines whether we're logging in (false) or signing up (true).
    @State private var isSignUpMode: Bool = false

    // Email form fields.
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isProcessing: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                // Background that adapts to light/dark mode.
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    // MARK: - Branding Section
                    VStack(spacing: 16) {
                        Image("logo") // Replace with your actual logo.
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.primary)
                        Text("Giveo")
                            .font(.custom("SourceSerifPro-Regular", size: 24))
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    // MARK: - Animated Lower Section
                    // When showEmailForm is false, display the auth option buttons;
                    // when true, display the email fields.
                    Group {
                        if showEmailForm {
                            emailFormView
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        } else {
                            authOptionsView
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .animation(.easeInOut, value: showEmailForm)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Authentication Options View (Default)
    private var authOptionsView: some View {
        VStack(spacing: 16) {
            // Stacked Email Auth Buttons
            Button(action: {
                withAnimation {
                    showEmailForm = true
                    isSignUpMode = false
                    authViewModel.errorMessage = nil
                }
            }) {
                Text("Log in")
                    .font(.custom("SourceSerifPro-Semibold", size: 16))
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor)
                    .cornerRadius(8)
            }
            
            Button(action: {
                withAnimation {
                    showEmailForm = true
                    isSignUpMode = true
                    authViewModel.errorMessage = nil
                }
            }) {
                Text("Sign up")
                    .font(.custom("SourceSerifPro-Semibold", size: 16))
                    .foregroundColor(.primary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.primary, lineWidth: 1)
                    )
            }
            
            // Divider between email auth and social sign in.
            Divider()
                .background(Color.secondary)
                .padding(.horizontal, 50)
            
            // Google Sign In Button
            Button(action: {
                print("Google Login tapped")
                // Call your view model's Google sign in function here.
            }) {
                HStack {
                    Image("google_logo") // Ensure you have a Google logo asset.
                        .resizable()
                        .frame(width: 20, height: 20)
                    Text("Google")
                }
                .font(.custom("SourceSerifPro-Semibold", size: 16))
                .foregroundColor(.primary)
                .padding()
                .frame(maxWidth: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.primary, lineWidth: 1)
                )
            }
            
            // Apple Sign In Button
            SignInWithAppleButton(
                .signIn,
                onRequest: configureAppleSignIn,
                onCompletion: handleAppleSignIn
            )
            .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
            .frame(height: 50)
            .cornerRadius(8)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Email Form View
    private var emailFormView: some View {
        ScrollView {
            VStack(spacing: 16) {
                if isProcessing {
                    ProgressView(isSignUpMode ? "Signing Up..." : "Logging In...")
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.accentColor))
                        .font(.custom("SourceSerifPro-Semibold", size: 16))
                        .transition(.opacity)
                } else {
                    if isSignUpMode {
                        TextField("Name", text: $name)
                            .autocapitalization(.words)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                            .font(.custom("SourceSerifPro-Regular", size: 16))
                            .transition(.move(edge: .leading).combined(with: .opacity))
                    }
                    
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                        .font(.custom("SourceSerifPro-Regular", size: 16))
                        .transition(.move(edge: .leading).combined(with: .opacity))
                    
                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                        .font(.custom("SourceSerifPro-Regular", size: 16))
                        .transition(.move(edge: .leading).combined(with: .opacity))
                    
                    if let error = authViewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .transition(.opacity)
                    }
                    
                    Button(action: {
                        withAnimation {
                            isProcessing = true
                        }
                        
                        if isSignUpMode {
                            guard !name.isEmpty else {
                                authViewModel.errorMessage = "Please enter your name."
                                withAnimation { isProcessing = false }
                                return
                            }
                            authViewModel.signUp(email: email, password: password, name: name)
                        } else {
                            authViewModel.signIn(email: email, password: password)
                        }
                    }) {
                        Text(isSignUpMode ? "Sign Up" : "Sign In")
                            .font(.custom("SourceSerifPro-Semibold", size: 16))
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.accentColor)
                            .cornerRadius(8)
                    }
                    .transition(.opacity)
                    
                    Button(action: {
                        withAnimation {
                            showEmailForm = false
                            authViewModel.errorMessage = nil
                            // Optionally clear the fields.
                            name = ""
                            email = ""
                            password = ""
                            isProcessing = false
                        }
                    }) {
                        Text("Back")
                            .font(.footnote)
                            .foregroundColor(.primary)
                    }
                    .transition(.opacity)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
    
    // MARK: - Apple Sign In Workflow Methods
    private func configureAppleSignIn(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
        let nonce = randomNonceString()
        request.nonce = sha256(nonce)
    }
    
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = appleIDCredential.identityToken,
                  let tokenString = String(data: tokenData, encoding: .utf8)
            else {
                authViewModel.errorMessage = "Unable to fetch Apple credentials."
                return
            }
            
            // Note: You should properly manage the nonce.
            let nonce = ""
            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                      idToken: tokenString,
                                                      rawNonce: nonce)
            authViewModel.signInWithApple(credential: credential)
            
        case .failure(let error):
            authViewModel.errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Nonce Helpers
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            var randoms = [UInt8](repeating: 0, count: 16)
            let errorCode = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
            if errorCode != errSecSuccess {
                fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
            }
            
            for random in randoms {
                if remainingLength == 0 { break }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.map { String(format: "%02x", $0) }.joined()
    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
            .environmentObject(AuthViewModel())
    }
}
