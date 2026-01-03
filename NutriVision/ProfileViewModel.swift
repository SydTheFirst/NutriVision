//
//  ProfileViewModel.swift
//  NutriVision
//
//  Created by Marco Ferreira on 03/01/2026.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class ProfileViewModel: ObservableObject {
    
    // MARK: - User & Environment
    @Published var user: User?
    @Published var isEditing = false
    @Published var showDeleteAlert = false
    @Published var showLogoutAlert = false
    @Published var isDeleting = false
    
    // MARK: - Editable fields
    @Published var editName = ""
    @Published var editAge = ""
    @Published var editHeight = ""
    @Published var editWeight = ""
    @Published var editGender: Gender = .other
    @Published var editWeightGoal: WeightGoal = .maintain
    @Published var calculatedDailyCalories: Double = 2000
    
    // MARK: - Alerts
    @Published var showAlert = false
    @Published var alertMessage = ""
    
    // MARK: - Auth
    var userCredential: AuthDataResult?
    
    // MARK: - Initialization
    init(user: User? = nil, userCredential: AuthDataResult? = nil) {
        self.user = user
        self.userCredential = userCredential
    }
    
    // MARK: - Form Validation
    var isFormValid: Bool {
        guard !editName.isEmpty,
              Double(editWeight) != nil,
              Int(editHeight) != nil,
              Int(editAge) != nil else {
            return false
        }
        return true
    }
    
    // MARK: - Editing Functions
    func startEditing() {
        editName = user?.name ?? ""
        editAge = "\(user?.age ?? 0)"
        editHeight = "\(user?.height ?? 0)"
        editWeight = String(format: "%.1f", user?.weight ?? 0.0)
        
        editGender = user?.gender ?? .other
        editWeightGoal = user?.weightGoal ?? .maintain
        calculatedDailyCalories = user?.dailyCalories ?? 2000
        
        isEditing = true
    }
    
    func cancelEditing() {
        isEditing = false
    }
    
    // MARK: - Daily Calories Calculation
    func calculateDailyCalories() -> Double {
        guard let w = Double(editWeight),
              let h = Double(editHeight),
              let a = Double(editAge) else {
            return 2000
        }

        var bmr: Double = 0

        switch editGender {
        case .male:
            bmr = 10 * w + 6.25 * h - 5 * a + 5
        case .female:
            bmr = 10 * w + 6.25 * h - 5 * a - 161
        case .other:
            bmr = 10 * w + 6.25 * h - 5 * a
        }

        switch editWeightGoal {
        case .lose:
            return bmr - 500
        case .gain:
            return bmr + 500
        case .maintain:
            return bmr
        }
    }
    
    // MARK: - Save Profile
    func saveChanges() {
        guard isFormValid else {
            showAlert = true
            alertMessage = "Please fill in all fields correctly"
            return
        }
        
        guard let uid = Auth.auth().currentUser?.uid else {
            showAlert = true
            alertMessage = "User not authenticated"
            return
        }
        
        let db = Firestore.firestore()
        let dailyCalories = calculateDailyCalories()
        
        let updates: [String: Any] = [
            "name": editName,
            "age": Int(editAge) ?? 0,
            "height": Int(editHeight) ?? 0,
            "weight": Double(editWeight) ?? 0.0,
            "gender": editGender.rawValue,
            "goal": editWeightGoal.rawValue,
            "dailyCalorieGoal": dailyCalories
        ]
        
        db.collection("Users").document(uid).updateData(updates) { [weak self] error in
            if let error = error {
                print("Error updating user: \(error.localizedDescription)")
                return
            }
            
            self?.user = User(
                id: self?.user?.id,
                name: self?.editName ?? "",
                email: self?.user?.email ?? "",
                age: Int(self?.editAge ?? "0"),
                height: Int(self?.editHeight ?? "0"),
                weight: Double(self?.editWeight ?? "0") ?? 0.0,
                gender: self?.editGender ?? .other,
                weightGoal: self?.editWeightGoal ?? .maintain,
                dailyCalories: dailyCalories
            )
            
            self?.isEditing = false
        }
    }
    
    // MARK: - Cancel Handling
    func handleCancel() {
        guard userCredential != nil else {
            showCancelAlert()
            return
        }
        showCancelAlert()
    }
    
    private func showCancelAlert() {
        showAlert = true
        alertMessage = "Cancel action triggered"
    }
}
