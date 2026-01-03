//
//  RecordingViewModel.swift
//  NutriVision
//
//  Created by Marco Ferreira on 03/01/2026.
//


import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class RecordingViewModel: ObservableObject {

    // MARK: - State

    @Published var detectedIngredients: [Ingredient] = []
    @Published var showNamingAlert = false
    @Published var showAddTodayAlert = false
    @Published var mealName: String = ""
    @Published var isScanning = true
    @Published var todayCalories: Double = 0

    let dataManager: DataManager
    private let nutritionService: NutritionService

    // MARK: - Init

    init(
        dataManager: DataManager = DataManager(),
        nutritionService: NutritionService = NutritionService()
    ) {
        self.dataManager = dataManager
        self.nutritionService = nutritionService
    }

    // MARK: - Computed values

    var dailyCalorieGoal: Double {
        dataManager.getDailyCalorieGoal()
    }

    var totalCaloriesIncludingToday: Double {
        totalCalories + dataManager.todayCalories
    }

    var calorieProgress: Double {
        guard dailyCalorieGoal > 0 else { return 0 }
        return min(totalCaloriesIncludingToday / dailyCalorieGoal, 1.0)
    }

    var totalCalories: Double {
        detectedIngredients.reduce(0) { $0 + $1.calories }
    }

    var totalProtein: Double {
        detectedIngredients.reduce(0) { $0 + $1.protein }
    }

    var totalCarbs: Double {
        detectedIngredients.reduce(0) { $0 + $1.carbs }
    }

    var totalFats: Double {
        detectedIngredients.reduce(0) { $0 + $1.fats }
    }

    var totalIngredientAreaScore: CGFloat {
        detectedIngredients.reduce(0) { $0 + $1.areaScore }
    }

    // MARK: - Lifecycle

    func onAppear() {
        dataManager.fetchTodayCalories()
    }

    // MARK: - Actions

    func startSaveMeal() {
        isScanning = false
        showNamingAlert = true
    }

    func startAddToToday() {
        isScanning = false
        showAddTodayAlert = true
    }

    func cancelNaming() {
        mealName = ""
        isScanning = true
    }

    // MARK: - Detection

    func simulateDetection(name: String, grams: Int) {
        let placeholder = Ingredient(aiDetectedName: name)
        detectedIngredients.append(placeholder)

        Task {
            do {
                if let fetched = try await nutritionService.fetchNutrition(for: "\(grams)g \(name)") {
                    if let index = detectedIngredients.firstIndex(where: { $0.name == name }) {
                        var updated = fetched
                        updated.areaScore = CGFloat(grams) / 2.5
                        detectedIngredients[index] = updated
                    }
                }
            } catch {
                print("Simulation Error: \(error)")
            }
        }
    }

    func deleteIngredient(_ ingredient: Ingredient) {
        if let index = detectedIngredients.firstIndex(where: { $0.id == ingredient.id }) {
            let removed = detectedIngredients[index]
            detectedIngredients.remove(at: index)

            NotificationCenter.default.post(
                name: .removeIngredientARCard,
                object: removed.id
            )
        }
    }

    // MARK: - Persistence

    func saveMeal(dismiss: @escaping () -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let finalName = mealName.isEmpty ? "Detected Meal" : mealName

        let meal = Meal(
            userID: uid,
            name: finalName,
            date: Date(),
            isSaved: true,
            ingredients: detectedIngredients
        )

        do {
            try Firestore.firestore()
                .collection("Users")
                .document(uid)
                .collection("Meals")
                .addDocument(from: meal)

            triggerSuccessFeedback()
            dismiss()
        } catch {
            print(error.localizedDescription)
        }
    }

    func addToToday(dismiss: @escaping () -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let finalName = mealName.isEmpty ? "Quick Meal" : mealName

        let meal = Meal(
            userID: uid,
            name: finalName,
            date: Date(),
            isSaved: false,
            ingredients: detectedIngredients
        )

        do {
            try Firestore.firestore()
                .collection("Users")
                .document(uid)
                .collection("Meals")
                .addDocument(from: meal)

            triggerSuccessFeedback()
            dismiss()
        } catch {
            print(error.localizedDescription)
        }
    }

    private func triggerSuccessFeedback() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
