//
//  ProfileSetupViewModel.swift
//  NutriVision
//
//  Created by Marco Ferreira on 03/01/2026.
//


import Foundation
import FirebaseAuth
import FirebaseFirestore
import SwiftUI

final class ProfileSetupViewModel: ObservableObject {
    
    // MARK: - User Input
    @Published var name: String = ""
    @Published var age: String = ""
    @Published var height: String = ""
    @Published var weight: String = ""
    @Published var gender: Gender = .male
    @Published var weightGoal: WeightGoal = .maintain
    
    // MARK: - Alerts
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var showCancelAlert = false
    
    // MARK: - Other
    var email: String
    var userCredential: AuthDataResult?
    
    init(email: String = "", userCredential: AuthDataResult? = nil) {
        self.email = email
        self.userCredential = userCredential
    }
    
    // MARK: - Form Validation
    var isFormValid: Bool {
        guard !name.isEmpty,
              Double(age) != nil,
              Double(height) != nil,
              Double(weight) != nil else { return false }
        return true
    }
    
    // MARK: - Daily Calories Calculation
    func calculateDailyCalories() -> Double {
        guard let weightValue = Double(weight),
              let heightValue = Double(height),
              let ageValue = Double(age) else { return 0 }
        
        let bmr: Double
        
        switch gender {
        case .male:
            bmr = 10 * weightValue + 6.25 * heightValue - 5 * ageValue + 5
        case .female:
            bmr = 10 * weightValue + 6.25 * heightValue - 5 * ageValue - 161
        case .other:
            bmr = 10 * weightValue + 6.25 * heightValue - 5 * ageValue
        }
        
        switch weightGoal {
        case .maintain: return bmr
        case .lose: return bmr - 500
        case .gain: return bmr + 500
        }
    }
    
    // MARK: - Actions
    func handleCancel() {
        // Show alert if new user
        if userCredential != nil {
            showCancelAlert = true
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
        
        // Build user dictionary to save
        let userData: [String: Any] = [
            "name": name,
            "age": Int(age) ?? 0,
            "height": Int(height) ?? 0,
            "weight": Double(weight) ?? 0,
            "gender": gender.rawValue,
            "weightGoal": weightGoal.rawValue,
            "dailyCalories": calculateDailyCalories()
        ]
        
        let db = Firestore.firestore()
        db.collection("Users").document(uid).setData(userData, merge: true) { [weak self] error in
            if let error = error {
                self?.alertMessage = "Error saving profile: \(error.localizedDescription)"
                self?.showAlert = true
            }
        }
    }
}
