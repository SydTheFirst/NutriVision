//
//  PreviewData.swift
//  NutriVision
//
//  Created by Vasco Zambujo on 28/12/2025.
//

import SwiftUI
import FirebaseVertexAI
import FirebaseAuth
import FirebaseFirestore
import Foundation

extension Meal {
    static var heavyPreviewData: [Date: [Meal]] {
        let calendar = Calendar.current
        let now = Date()
        var data: [Date: [Meal]] = [:]
        
        // Define a wider variety of dummy ingredients
        let egg = Ingredient(name: "Eggs", amount: 2, unit: "large", calories: 140, protein: 12, carbs: 1, fats: 10)
        let chicken = Ingredient(name: "Chicken", amount: 200, unit: "g", calories: 330, protein: 60, carbs: 0, fats: 7)
        let rice = Ingredient(name: "Rice", amount: 1, unit: "cup", calories: 200, protein: 4, carbs: 45, fats: 0.5)
        let apple = Ingredient(name: "Apple", amount: 1, unit: "med", calories: 95, protein: 0.5, carbs: 25, fats: 0.3)
        let pizza = Ingredient(name: "Pizza", amount: 2, unit: "slices", calories: 570, protein: 24, carbs: 72, fats: 20)
        let salad = Ingredient(name: "Salad", amount: 1, unit: "bowl", calories: 45, protein: 1, carbs: 5, fats: 3)

        let allIngredients = [egg, chicken, rice, apple, pizza, salad]

        for dayOffset in 0...6 {
            let date = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -dayOffset, to: now)!)
            let numberOfMeals = Int.random(in: 2...4) // Ensure 2-4 meals per day
            var dayMeals: [Meal] = []
            
            for i in 0..<numberOfMeals {
                // Randomly pick 1-3 ingredients for this meal
                let ingredients = Array(allIngredients.shuffled().prefix(Int.random(in: 1...3)))
                
                // CRITICAL: Give each dummy meal a unique ID string
                let uniqueID = "dummy_\(dayOffset)_\(i)"
                
                let meal = Meal(
                    id: uniqueID,
                    userID: "test_user",
                    name: i == 0 ? "Breakfast" : (i == 1 ? "Detected Meal" : ""),
                    date: date.addingTimeInterval(TimeInterval(3600 * (8 + i))),
                    isSaved: true,
                    ingredients: ingredients
                )
                dayMeals.append(meal)
            }
            data[date] = dayMeals
        }
        return data
    }
}
