//
//  AuthView.swift
//  NutriVision
//
//  Created by Vasco Zambujo on 21/12/2025.
//

import SwiftUI
import Firebase

enum AuthType{
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
        NavigationStack{
            ScrollView(showsIndicators: false) {
                TopView()
                SegmentedView(authType: $authType)
                
                VStack(spacing: 15) {
                    TextField(text: $email) {
                        Text("Email")
                    }
                    .focused($isEmailFocused)
                    .textFieldStyle(AuthTextFieldStyle(isFocused: $isEmailFocused))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    
                    ZStack {
                        TextField(text: $password) {
                            Text("Password")
                        }
                        .focused($isPassFocused)
                        .textFieldStyle(AuthTextFieldStyle(isFocused: $isPassFocused))
                        .overlay(alignment: .trailing, content: {
                            Button{
                                withAnimation {
                                    showPass.toggle()
                                }
                            } label: {
                                Image(systemName: showPass ? "eye.fill" : "eye.slash.fill")
                                    .padding()
                                    .foregroundStyle(Color(UIColor.lightGray))
                            }
                        })
                        
                        SecureField(text: $password) {
                            Text("Password")
                        }
                        .focused($isPassFocused)
                        .textFieldStyle(AuthTextFieldStyle(isFocused: $isPassFocused))
                        .overlay(alignment: .trailing) {
                            Button{
                                withAnimation {
                                    showPass.toggle()
                                }
                            } label: {
                                Image(systemName: showPass ? "eye.fill" : "eye.slash.fill")
                                    .padding()
                                    .foregroundStyle(Color(UIColor.lightGray))
                            }
                        }
                        .opacity(showPass ? 0 : 1)
                    }
                }
                
                Button {
                    if authType == .login {
                        login()
                    } else {
                        register()
                    }
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
                
                BottomView(authType: $authType)
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
    
    func login() {
        isLoading = true
        Auth.auth().signIn(withEmail: email, password: password) { _, error in
            DispatchQueue.main.async {
                isLoading = false

                if let error = error {
                    alertMessage = error.localizedDescription
                    showAlert = true
                    return
                }
                appState.loadInitialState()
            }
        }
    }

    
    func register() {
        isLoading = true

        Auth.auth().createUser(withEmail: email, password: password) { _, error in
            DispatchQueue.main.async {
                isLoading = false

                if let error = error {
                    alertMessage = error.localizedDescription
                    showAlert = true
                    return
                }

                appState.isLoggedIn = true
                appState.needsProfileSetup = true
                appState.email = email
            }
        }
    }


    
    func checkProfileCompletion() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("Users").document(uid).getDocument { snapshot, error in
            if let data = snapshot?.data(),
               let profileCompleted = data["profileCompleted"] as? Bool,
               profileCompleted {
                navigateToHome()
            } else {
                // Profile not complete - go to setup
                pendingUserCredential = nil // Already logged in, just incomplete profile
                goToProfileSetup = true
            }
        }
    }
    
    func deleteIncompleteAccount() {
        // Delete the Firebase Auth account if profile setup was cancelled
        if let user = Auth.auth().currentUser {
            user.delete { error in
                if let error = error {
                    print("Error deleting incomplete account: \(error.localizedDescription)")
                }
            }
        }
        pendingUserCredential = nil
    }
    
    func navigateToHome() {
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let navController = window.rootViewController as? UINavigationController {
                navController.popToRootViewController(animated: true)
            }
        }
    }
}

struct AuthButtonType: ButtonStyle{
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(.vertical)
            .foregroundStyle(Color.white)
            .font(.system(size: 20, weight: .bold))
            .background(
                LinearGradient(stops: [
                    .init(color: .blue, location: 1.0)
                ], startPoint: .leading, endPoint: .trailing)
            )
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
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(isFocused.wrappedValue ? Color.blue : Color.gray.opacity(0.5), lineWidth: 1)
                        .zIndex(1)
                    
                    RoundedRectangle(cornerRadius: 16)
                        .fill(colorScheme == .light ? Color(uiColor: UIColor.systemGray6) : Color(uiColor: UIColor.systemGray5))
                        .zIndex(0)
                }
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused.wrappedValue)
    }
}

struct TopView: View {
    var body: some View {
        Image(systemName: "person.circle")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 75)
        
        Text("NutriVision")
            .font(.system(size: 35, weight: .bold))
    }
}

struct SegmentedView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var authType: AuthType
    
    var body: some View {
        HStack(spacing:0) {
            Button {
                withAnimation {
                    authType = .login
                }
            } label: {
                Text("Login")
                    .fontWeight(authType == .login ? .semibold : .regular)
                    .foregroundStyle(authType == .login ? (colorScheme == .light ? Color(uiColor: UIColor.darkGray) : .white) : .gray)
                    .padding(.vertical, 12)
                    .padding(.horizontal, authType == .login ? 30 : 20)
                    .background(
                        ZStack{
                            if authType == .login {
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.black.opacity(0.3), lineWidth: 0.5)
                                    .zIndex(1)
                            }
                            
                            RoundedRectangle(cornerRadius: 20)
                                .fill(authType == .login ?
                                      Color(UIColor.systemGray5) :
                                        Color(UIColor.systemGray6))
                                .zIndex(0)
                        })
            }
            
            Button {
                withAnimation {
                    authType = .register
                }
            } label: {
                Text("Register")
                    .fontWeight(authType == .register ? .semibold : .regular)
                    .foregroundStyle(authType == .register ? (colorScheme == .light ? Color(uiColor: UIColor.darkGray) : .white) : .gray)
                    .padding(.vertical, 12)
                    .padding(.horizontal, authType == .register ? 30 : 20)
                    .background(
                        ZStack{
                            if authType == .register {
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.black.opacity(0.3), lineWidth: 0.5)
                                    .zIndex(1)
                            }
                            
                            RoundedRectangle(cornerRadius: 20)
                                .fill(authType == .register ?
                                      Color(UIColor.systemGray5) :
                                        Color(UIColor.systemGray6))
                                .zIndex(0)
                        })
            }
        }
        .background(
            Color(UIColor.systemGray6)
        )
        .cornerRadius(20)
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity)
    }
}

struct BottomView: View{
    @Environment(\.colorScheme) private var colorScheme
    @Binding var authType: AuthType
    
    var body: some View{
        VStack(spacing: 20){
            HStack(spacing: 3){
                Text(authType == .login ? "Don't have an account?" : "Already have an account?")
                    .font(.system(size: 15, weight: .medium))
                
                Button {
                    if authType == .login{
                        withAnimation{
                            authType = .register
                        }
                    } else {
                        withAnimation{
                            authType = .login
                        }
                    }
                } label: {
                    Text(authType == .login ? "Register" : "Login")
                        .font(.system(size: 15, weight: .bold))
                }
            }
            
            HStack {
                Rectangle()
                    .frame(height: 1.5)
                    .foregroundStyle(Color.gray.opacity(0.3))
                Text("OR")
                    .font(.system(size: 14, weight: .regular))
                Rectangle()
                    .frame(height: 1.5)
                    .foregroundStyle(Color.gray.opacity(0.3))
            }
            
            HStack(spacing: 20) {
                //apple
                Button {
                    
                } label: {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(lineWidth: 1.5)
                        .frame(width: 40, height: 40)
                        .foregroundStyle(.opacity(0))
                        .overlay {
                            Image(systemName: "apple.logo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20)
                                .foregroundStyle(colorScheme == .light ? .black : .white)
                        }
                }
                
                //google
                Button {
                    
                } label: {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(lineWidth: 1.5)
                        .frame(width: 40, height: 40)
                        .foregroundStyle(.opacity(0))
                        .overlay {
                            Image("google")
                                .renderingMode(.template)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20)
                        }
                }
            }
        }
    }
}
