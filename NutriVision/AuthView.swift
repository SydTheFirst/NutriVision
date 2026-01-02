//
//  AuthView.swift
//  NutriVision
//
//  Created by Vasco Zambujo on 21/12/2025.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import GoogleSignInSwift

enum AuthType {
    case login
    case register
}

struct AuthView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var appState: AppState
    
    @State private var email: String = ""
    @State private var password: String = ""
    
    @State private var goToProfileSetup = false
    @State private var pendingUserCredential: AuthDataResult?
    
    @FocusState private var isEmailFocused
    @FocusState private var isPassFocused
        
    @State private var showPass = false
    @State private var authType: AuthType = .login
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                TopView()
                SegmentedView(authType: $authType)
                
                VStack(spacing: 15) {
                    TextField("Email", text: $email)
                        .focused($isEmailFocused)
                        .textFieldStyle(AuthTextFieldStyle(isFocused: $isEmailFocused))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    ZStack {
                        if showPass {
                            TextField("Password", text: $password)
                                .focused($isPassFocused)
                                .textFieldStyle(AuthTextFieldStyle(isFocused: $isPassFocused))
                        } else {
                            SecureField("Password", text: $password)
                                .focused($isPassFocused)
                                .textFieldStyle(AuthTextFieldStyle(isFocused: $isPassFocused))
                        }
                    }
                    .overlay(alignment: .trailing) {
                        Button {
                            withAnimation { showPass.toggle() }
                        } label: {
                            Image(systemName: showPass ? "eye.fill" : "eye.slash.fill")
                                .padding()
                                .foregroundStyle(Color(UIColor.lightGray))
                        }
                    }
                }
                
                Button {
                    authType == .login ? login() : register()
                } label: {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(authType == .login ? "Login" : "Register")
                    }
                }
                .buttonStyle(AuthButtonType())
                .disabled(isLoading || email.isEmpty || password.isEmpty)
                .opacity((email.isEmpty || password.isEmpty) ? 0.6 : 1.0)
                
                // Pass the googleAction here
                BottomView(authType: $authType, googleAction: {
                    signInWithGoogle()
                })
            }
            .padding()
            .navigationDestination(isPresented: $goToProfileSetup) {
                ProfileSetupView(
                    email: email,
                    userCredential: pendingUserCredential,
                    onProfileComplete: {
                        appState.needsProfileSetup = false
                    },
                    onCancel: {
                        deleteIncompleteAccount()
                    }
                )
            }
            .alert("Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // MARK: - Auth Logic
    func login() {
        isLoading = true
        Auth.auth().signIn(withEmail: email, password: password) { _, error in
            handleFirebaseResponse(result: nil, error: error)
        }
    }

    func register() {
        isLoading = true
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            handleFirebaseResponse(result: result, error: error)
        }
    }

    // MARK: - Google Sign In
    func signInWithGoogle() {
        // 1. Get Client ID from Firebase options
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        // 2. Find the root view controller to present the Google popup
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else { return }

        isLoading = true
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            if let error = error {
                isLoading = false
                print("Google error: \(error.localizedDescription)")
                return
            }

            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                isLoading = false
                return
            }

            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: user.accessToken.tokenString)
            
            Auth.auth().signIn(with: credential) { authResult, error in
                handleFirebaseResponse(result: authResult, error: error)
            }
        }
    }

    private func handleFirebaseResponse(result: AuthDataResult?, error: Error?) {
        DispatchQueue.main.async {
            isLoading = false
            if let error = error {
                alertMessage = error.localizedDescription
                showAlert = true
                return
            }
            
            // If it's a new user (via Register or first time Google)
            if let isNew = result?.additionalUserInfo?.isNewUser, isNew {
                appState.isLoggedIn = true
                appState.needsProfileSetup = true
                appState.email = result?.user.email ?? email
                pendingUserCredential = result
                goToProfileSetup = true
            } else {
                // Existing user
                appState.loadInitialState()
            }
        }
    }
    
    func deleteIncompleteAccount() {
        if let user = Auth.auth().currentUser {
            user.delete { error in
                if let error = error {
                    print("Error deleting account: \(error.localizedDescription)")
                }
            }
        }
        pendingUserCredential = nil
    }
}

// MARK: - UI Components (No changes needed to styles)

struct AuthButtonType: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(.vertical)
            .foregroundStyle(Color.white)
            .font(.system(size: 20, weight: .bold))
            .background(Color.blue)
            .cornerRadius(15)
            .brightness(configuration.isPressed ? 0.05 : 0)
            .opacity(configuration.isPressed ? 0.5 : 1)
            .padding(.vertical, 12)
    }
}

struct AuthTextFieldStyle: TextFieldStyle {
    @Environment(\.colorScheme) private var colorScheme
    let isFocused: FocusState<Bool>.Binding
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .light ? Color(UIColor.systemGray6) : Color(UIColor.systemGray5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isFocused.wrappedValue ? Color.blue : Color.gray.opacity(0.5), lineWidth: 1)
                    )
            )
    }
}

struct TopView: View {
    var body: some View {
        VStack {
            Image(systemName: "person.circle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 75)
            
            Text("NutriVision")
                .font(.system(size: 35, weight: .bold))
        }
        .padding(.top, 20)
    }
}

struct SegmentedView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var authType: AuthType
    
    var body: some View {
        HStack(spacing: 0) {
            segmentButton(title: "Login", type: .login)
            segmentButton(title: "Register", type: .register)
        }
        .background(Color(UIColor.systemGray6))
        .cornerRadius(20)
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }
    
    private func segmentButton(title: String, type: AuthType) -> some View {
        Button {
            withAnimation { authType = type }
        } label: {
            Text(title)
                .fontWeight(authType == type ? .semibold : .regular)
                .foregroundStyle(authType == type ? (colorScheme == .light ? .black : .white) : .gray)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(authType == type ? Color(UIColor.systemGray4) : Color.clear)
                .cornerRadius(20)
        }
    }
}

struct BottomView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var authType: AuthType
    var googleAction: () -> Void // New callback
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 3) {
                Text(authType == .login ? "Don't have an account?" : "Already have an account?")
                    .font(.system(size: 15))
                
                Button {
                    withAnimation { authType = (authType == .login ? .register : .login) }
                } label: {
                    Text(authType == .login ? "Register" : "Login")
                        .font(.system(size: 15, weight: .bold))
                }
            }
            
            HStack {
                line; Text("OR").font(.caption); line
            }
            
            HStack() {
                // Google
                Button(action: googleAction) {
                    socialIcon(imageName: "google")
                }
            }
        }
    }
    
    var line: some View {
        Rectangle().frame(height: 1).foregroundStyle(Color.gray.opacity(0.3))
    }
    
    private func socialIcon(systemName: String? = nil, imageName: String? = nil) -> some View {
        RoundedRectangle(cornerRadius: 10)
            .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
            .frame(width: 44, height: 44)
            .overlay {
                if let systemName = systemName {
                    Image(systemName: systemName)
                        .foregroundStyle(colorScheme == .light ? .black : .white)
                } else if let imageName = imageName {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 22)
                }
            }
    }
}
