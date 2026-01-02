//
//  DataManager.swift
//  NutriVision
//
//  Created by Vasco Zambujo on 22/12/2025.
//

import SwiftUI
import Firebase

class DataManager: ObservableObject {
    @Published var users: [User] = []
    @Published var currentUser: User? = nil
    @Published var todayCalories: Double = 0
    
    private let db = Firestore.firestore()
    
    init() {
        fetchUsers()
    }
    
    func fetchUsers() {
        users.removeAll()
        db.collection("Users").getDocuments { snapshot, error in
            guard error == nil else {
                print(error!.localizedDescription)
                return
            }
            
            snapshot?.documents.forEach { document in
                let data = document.data()
                let id = document.documentID
                let name = data["name"] as? String ?? ""
                let email = data["email"] as? String ?? ""
                let age = data["age"] as? Int
                let height = data["height"] as? Int
                let weight = data["weight"] as? Double
                let dailyCalories = data["dailyCalorieGoal"] as? Double
                
                let genderString = data["gender"] as? String
                let gender = genderString.flatMap { Gender(rawValue: $0) }
                
                let weightGoalString = data["weightGoal"] as? String
                let weightGoal = weightGoalString.flatMap { WeightGoal(rawValue: $0) }
                
                let user = User(
                    id: id,
                    name: name,
                    email: email,
                    age: age,
                    height: height,
                    weight: weight,
                    gender: gender,
                    weightGoal: weightGoal,
                    dailyCalories: dailyCalories
                )
                
                self.users.append(user)
                
                // If current logged-in user
                if let uid = Auth.auth().currentUser?.uid, uid == id {
                    self.currentUser = user
                }
            }
        }
    }
    
    // Optional helper to get current user's daily calorie goal
    func getDailyCalorieGoal() -> Double {
        currentUser?.dailyCalories ?? 2000
    }
    
    func fetchTodayCalories() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

        db.collection("Users").document(uid).collection("Meals")
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startOfDay))
            .whereField("date", isLessThan: Timestamp(date: endOfDay))
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching today's meals: \(error)")
                    return
                }

                let meals = snapshot?.documents.compactMap { doc -> Meal? in
                    try? doc.data(as: Meal.self)
                } ?? []

                let total = meals.reduce(0) { $0 + $1.calories }

                DispatchQueue.main.async {
                    self?.todayCalories = total
                }
            }
    }
}
