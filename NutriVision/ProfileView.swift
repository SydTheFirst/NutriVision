//
//  ProfileView.swift
//  NutriVision
//
//  Created by Vasco Zambujo on 22/12/2025.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState

    @Binding var user: User?
    
    @State private var isEditing = false
    @State private var showDeleteAlert = false
    @State private var showLogoutAlert = false
    @State private var isDeleting = false
    
    // Editable fields
    @State private var editName = ""
    @State private var editAge = ""
    @State private var editHeight = ""
    @State private var editWeight = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    // Profile Header
                    VStack(spacing: 15) {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .blue.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text(user?.name ?? "User")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        
                        Text(user?.email ?? "")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 20)
                    
                    // Profile Information
                    VStack(spacing: 20) {
                        if isEditing {
                            // Edit Mode
                            VStack(spacing: 15) {
                                ProfileEditField(title: "Name", text: $editName, icon: "person.fill")
                                ProfileEditField(title: "Age", text: $editAge, icon: "calendar", keyboardType: .numberPad)
                                ProfileEditField(title: "Height (cm)", text: $editHeight, icon: "ruler", keyboardType: .numberPad)
                                ProfileEditField(title: "Weight (kg)", text: $editWeight, icon: "scalemass", keyboardType: .decimalPad)
                            }
                            
                            // Save Changes Button
                            Button {
                                saveChanges()
                            } label: {
                                Text("Save Changes")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        LinearGradient(
                                            colors: [.blue, .blue.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                            
                        } else {
                            // View Mode
                            VStack(spacing: 15) {
                                ProfileInfoRow(icon: "person.fill", label: "Name", value: user?.name ?? "N/A")
                                ProfileInfoRow(icon: "calendar", label: "Age", value: "\(user?.age ?? 0)")
                                ProfileInfoRow(icon: "ruler", label: "Height", value: "\(user?.height ?? 0) cm")
                                ProfileInfoRow(icon: "scalemass", label: "Weight", value: String(format: "%.1f kg", user?.weight ?? 0.0))
                            }
                            
                            // Edit Profile Button
                            Button {
                                startEditing()
                            } label: {
                                Text("Edit Profile")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        LinearGradient(
                                            colors: [.blue, .blue.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Danger Zone
                    VStack(spacing: 15) {
                        // Logout Button
                        Button {
                            showLogoutAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Logout")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.orange)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.orange, lineWidth: 2)
                            )
                        }
                        .padding(.horizontal)
                        
                        // Delete Account Button
                        Button {
                            showDeleteAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("Delete Account")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red, lineWidth: 2)
                            )
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 20)
                }
                .padding(.bottom, 30)
            }
            .background(Color(colorScheme == .light ? .systemGroupedBackground : .black))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if isEditing {
                            cancelEditing()
                        } else {
                            dismiss()
                        }
                    } label: {
                        Text(isEditing ? "Cancel" : "Done")
                            .foregroundColor(isEditing ? .red : .blue)
                    }
                }
            }
            .alert("Logout", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Logout", role: .destructive) {
                    logout()
                }
            } message: {
                Text("Are you sure you want to logout?")
            }
            .alert("Delete Account", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteAccount()
                }
            } message: {
                Text("This action is permanent and cannot be undone. All your data will be deleted.")
            }
        }
    }
    
    func startEditing() {
        editName = user?.name ?? ""
        editAge = "\(user?.age ?? 0)"
        editHeight = "\(user?.height ?? 0)"
        editWeight = String(format: "%.1f", user?.weight ?? 0.0)
        isEditing = true
    }
    
    func cancelEditing() {
        isEditing = false
    }
    
    func saveChanges() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("Users").document(uid).updateData([
            "name": editName,
            "age": Int(editAge) ?? 0,
            "height": Int(editHeight) ?? 0,
            "weight": Double(editWeight) ?? 0.0
        ]) { error in
            if error == nil {
                // Update local user object
                user = User(
                    id: user?.id,
                    name: editName,
                    email: user?.email ?? "",
                    age: Int(editAge),
                    height: Int(editHeight),
                    weight: Double(editWeight)
                )
                isEditing = false
            }
        }
    }
    
    func logout() {
        do {
            try Auth.auth().signOut()
            appState.logout()
        } catch {
            print("Error signing out:", error.localizedDescription)
        }
    }

    
    func deleteAccount() {
        guard let user = Auth.auth().currentUser else { return }
        guard let uid = user.uid as String? else { return }
        
        isDeleting = true
        
        // Delete Firestore data first
        let db = Firestore.firestore()
        db.collection("Users").document(uid).delete { error in
            if let error = error {
                print("Error deleting user data: \(error.localizedDescription)")
                isDeleting = false
                return
            }
            
            // Then delete the auth account
            user.delete { error in
                isDeleting = false
                
                if let error = error {
                    print("Error deleting account: \(error.localizedDescription)")
                } else {
                    appState.isLoggedIn = false
                    dismiss()
                }
            }
        }
    }
}

struct ProfileInfoRow: View {
    let icon: String
    let label: String
    let value: String
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 35)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)
                
                Text(value)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .light ? Color.white : Color(uiColor: .systemGray6))
        )
        .padding(.horizontal)
    }
}

struct ProfileEditField: View {
    let title: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .frame(width: 30)
            
            TextField(title, text: $text)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .keyboardType(keyboardType)
                .focused($isFocused)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isFocused ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1.5)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorScheme == .light ? Color.white : Color(uiColor: .systemGray6))
                )
        )
        .padding(.horizontal)
    }
}
