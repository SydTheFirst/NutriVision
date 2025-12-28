//
//  DailyNutrition.swift
//  NutriVision
//
//  Created by Vasco Zambujo on 26/12/2025.
//

import Foundation
import FirebaseFirestore

struct DailyNutrition: Identifiable, Codable {
    @DocumentID var id: String?
    let date: Date
    let totalCalories: Double
    let totalProtein: Double
    let totalCarbs: Double
    let totalFats: Double
}
