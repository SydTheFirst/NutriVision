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
    
    @StateObject var vm: ProfileViewModel
    
    init(user: User) {
        _vm = StateObject(wrappedValue: ProfileViewModel(user: user))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    profileHeader
                    profileInfoSection
                    dangerZoneSection
                }
                .padding(.bottom, 30)
            }
            .background(Color(colorScheme == .light ? .systemGroupedBackground : .black))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if vm.isEditing {
                            vm.cancelEditing()
                        } else {
                            dismiss()
                        }
                    } label: {
                        Text(vm.isEditing ? "Cancel" : "Done")
                            .foregroundColor(vm.isEditing ? .red : .blue)
                    }
                }
            }
        }
        .confirmationDialog(
            "Logout",
            isPresented: $vm.showLogoutAlert,
            titleVisibility: .visible
        ) {
            Button("Logout", role: .destructive) {
                vm.logout()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to logout?")
        }
        .confirmationDialog(
            "Delete Account",
            isPresented: $vm.showDeleteAlert,
            titleVisibility: .visible
        ) {
            Button("Delete Account", role: .destructive) {
                vm.deleteAccount()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action is permanent and cannot be undone.")
        }
        .onChange(of: vm.didLogout) { didLogout in
            guard didLogout else { return }
            appState.logout()
            dismiss()
        }

        .onChange(of: vm.didDeleteAccount) { didDelete in
            guard didDelete else { return }
            appState.isLoggedIn = false
            dismiss()
        }
    }
    
    // MARK: - Subviews
    
    private var profileHeader: some View {
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
            
            Text(vm.user?.name ?? "User")
                .font(.system(size: 28, weight: .bold, design: .rounded))
            
            Text(vm.user?.email ?? "")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.gray)
        }
        .padding(.top, 20)
    }
    
    private var profileInfoSection: some View {
        VStack(spacing: 20) {
            if vm.isEditing {
                editModeSection
            } else {
                viewModeSection
            }
        }
    }
    
    private var editModeSection: some View {
        VStack(spacing: 15) {
            ProfileEditField(title: "Name", text: $vm.editName, icon: "person.fill")
            ProfileEditField(title: "Age", text: $vm.editAge, icon: "calendar", keyboardType: .numberPad)
            ProfileEditField(title: "Height (cm)", text: $vm.editHeight, icon: "ruler", keyboardType: .numberPad)
            ProfileEditField(title: "Weight (kg)", text: $vm.editWeight, icon: "scalemass", keyboardType: .decimalPad)
            
            genderPicker
            weightGoalPicker
            dailyCaloriesView
            
            Button {
                vm.saveChanges()
            } label: {
                Text("Save Changes")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(colors: [.blue, .blue.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
    }
    
    private var viewModeSection: some View {
        VStack(spacing: 15) {
            ProfileInfoRow(icon: "person.fill", label: "Name", value: vm.user?.name ?? "N/A")
            ProfileInfoRow(icon: "calendar", label: "Age", value: "\(vm.user?.age ?? 0)")
            ProfileInfoRow(icon: "ruler", label: "Height", value: "\(vm.user?.height ?? 0) cm")
            ProfileInfoRow(icon: "scalemass", label: "Weight", value: String(format: "%.1f kg", vm.user?.weight ?? 0.0))
            ProfileInfoRow(icon: "person.2.fill", label: "Gender", value: vm.user?.gender?.rawValue.capitalized ?? "N/A")
            ProfileInfoRow(
                icon: "target",
                label: "Goal",
                value: (vm.user?.weightGoal?.rawValue.capitalized ?? "N/A") + " weight"
            )
            ProfileInfoRow(icon: "flame.fill", label: "Daily Calories", value: "\(Int(vm.user?.dailyCalories ?? 2000)) kcal")
            
            Button {
                vm.startEditing()
            } label: {
                Text("Edit Profile")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LinearGradient(colors: [.blue, .blue.opacity(0.8)], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
    }
    
    private var genderPicker: some View {
        Picker("Gender", selection: $vm.editGender) {
            ForEach(Gender.allCases, id: \.self) { gender in
                Text(gender.rawValue.capitalized).tag(gender)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
    }
    
    private var weightGoalPicker: some View {
        Picker("Weight Goal", selection: $vm.editWeightGoal) {
            ForEach(WeightGoal.allCases, id: \.self) { goal in
                Text(goal.rawValue.capitalized).tag(goal)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
    }
    
    private var dailyCaloriesView: some View {
        HStack(spacing: 15) {
            Image(systemName: "flame.fill")
                .font(.system(size: 20))
                .foregroundColor(.orange)
                .frame(width: 30)
            
            Text("\(Int(vm.calculatedDailyCalories)) kcal")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.gray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .light ? Color.white : Color(uiColor: .systemGray6))
        )
        .padding(.horizontal)
    }
    
    private var dangerZoneSection: some View {
        VStack(spacing: 15) {
            Button {
                vm.showLogoutAlert = true
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Logout")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.orange)
                .frame(maxWidth: .infinity)
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).stroke(Color.orange, lineWidth: 2))
            }
            .padding(.horizontal)
            
            Button {
                vm.showDeleteAlert = true
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Delete Account")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).stroke(Color.red, lineWidth: 2))
            }
            .padding(.horizontal)
        }
        .padding(.top, 20)
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
