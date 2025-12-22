//
//  ProfileSetupView.swift
//  NutriVision
//
//  Created by Vasco Zambujo on 22/12/2025.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ProfileSetupView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    let email: String
    let userCredential: AuthDataResult?
    let onProfileComplete: () -> Void
    let onCancel: () -> Void
    
    @State private var name = ""
    @State private var age = ""
    @State private var height = ""
    @State private var weight = ""
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isSaving = false
    
    @FocusState private var isNameFocused: Bool
    @FocusState private var isAgeFocused: Bool
    @FocusState private var isHeightFocused: Bool
    @FocusState private var isWeightFocused: Bool
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Complete your profile")
                        .font(.system(size: 32, weight: .bold))
                    
                    Text(email)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                        .padding(.bottom, 10)
                }
                .padding(.top, 20)
                
                // Form Fields
                VStack(spacing: 15) {
                    TextField(text: $name) {
                        Text("Name")
                    }
                    .focused($isNameFocused)
                    .textFieldStyle(ProfileTextFieldStyle(isFocused: $isNameFocused))
                    
                    TextField(text: $age) {
                        Text("Age")
                    }
                    .keyboardType(.numberPad)
                    .focused($isAgeFocused)
                    .textFieldStyle(ProfileTextFieldStyle(isFocused: $isAgeFocused))
                    
                    TextField(text: $height) {
                        Text("Height (cm)")
                    }
                    .keyboardType(.numberPad)
                    .focused($isHeightFocused)
                    .textFieldStyle(ProfileTextFieldStyle(isFocused: $isHeightFocused))
                    
                    TextField(text: $weight) {
                        Text("Weight (kg)")
                    }
                    .keyboardType(.decimalPad)
                    .focused($isWeightFocused)
                    .textFieldStyle(ProfileTextFieldStyle(isFocused: $isWeightFocused))
                }
                
                // Save Button
                Button {
                    saveProfile()
                } label: {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Save Profile")
                    }
                }
                .buttonStyle(ProfileButtonStyle())
                .disabled(isSaving || !isFormValid)
                .opacity(isFormValid ? 1.0 : 0.6)
                
            }
            .padding()
        }
        .onAppear {
            // Hide the UIKit navigation back button and configure navigation bar
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let navController = windowScene.windows.first?.rootViewController as? UINavigationController {
                navController.navigationBar.topItem?.setHidesBackButton(true, animated: false)
                // Ensure navigation bar is visible
                navController.setNavigationBarHidden(false, animated: false)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    handleCancel()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                        Text("Cancel")
                            .font(.system(size: 17))
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .interactiveDismissDisabled(true)
        .alert("Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .alert("Cancel Registration", isPresented: $showCancelAlert) {
            Button("Continue Setup", role: .cancel) { }
            Button("Delete Account", role: .destructive) {
                onCancel()
                dismiss()
            }
        } message: {
            Text("Are you sure you want to cancel? Your account will be deleted.")
        }
    }
    
    @State private var showCancelAlert = false
    
    var isFormValid: Bool {
        !name.isEmpty &&
        !age.isEmpty &&
        !height.isEmpty &&
        !weight.isEmpty &&
        Int(age) != nil &&
        Int(height) != nil &&
        Double(weight) != nil
    }
    
    func handleCancel() {
        // Show confirmation for new registrations, allow direct cancel for existing users
        if userCredential != nil {
            showCancelAlert = true
        } else {
            dismiss()
        }
    }
    
    func saveProfile() {
        guard isFormValid else {
            alertMessage = "Please fill in all fields correctly"
            showAlert = true
            return
        }
        
        guard let uid = Auth.auth().currentUser?.uid else {
            alertMessage = "User not authenticated"
            showAlert = true
            return
        }
        
        isSaving = true
        
        let db = Firestore.firestore()
        
        db.collection("Users").document(uid).setData([
            "email": email,
            "name": name,
            "age": Int(age) ?? 0,
            "height": Int(height) ?? 0,
            "weight": Double(weight) ?? 0.0,
            "profileCompleted": true,
            "createdAt": FieldValue.serverTimestamp()
        ]) { error in
            isSaving = false
            
            if let error = error {
                alertMessage = error.localizedDescription
                showAlert = true
            } else {
                onProfileComplete()
            }
        }
    }
}

struct ProfileTextFieldStyle: TextFieldStyle {
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

struct ProfileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(Color.white)
            .font(.system(size: 20, weight: .bold))
            .background(
                LinearGradient(
                    stops: [.init(color: .blue, location: 1.0)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(15)
            .brightness(configuration.isPressed ? 0.05 : 0)
            .opacity(configuration.isPressed ? 0.5 : 1)
            .padding(.vertical, 12)
    }
}
