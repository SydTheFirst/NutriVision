//
//  Ingredient.swift
//  NutriVision
//
//  Created by Vasco Zambujo on 26/12/2025.
//

import Foundation
import CoreGraphics

struct Ingredient: Identifiable, Equatable, Codable, Hashable {
    var id = UUID()
    let name: String
    let amount: Double
    let unit: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fats: Double
    
    // Runtime-only
    var detectedFrames: Int = 0
    var areaScore: CGFloat = 0.0
    
    enum CodingKeys: String, CodingKey {
        case name, amount, unit, calories, protein, carbs, fats
    }
    
    var formattedAmount: String {
        if amount.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(amount)) \(unit)"
        } else {
            return String(format: "%.1f %@", amount, unit)
        }
    }
    
    init(name: String,
         amount: Double,
         unit: String,
         calories: Double,
         protein: Double? = nil,
         carbs: Double? = nil,
         fats: Double? = nil) {
        self.name = name
        self.amount = amount
        self.unit = unit
        self.calories = calories
        self.protein = protein ?? 0.0
        self.carbs = carbs ?? 0.0
        self.fats = fats ?? 0.0
    }
    
    init(aiDetectedName: String,
         estimatedAmount: Double = 1,
         unit: String = "serving") {
        self.name = aiDetectedName
        self.amount = estimatedAmount
        self.unit = unit
        self.calories = 0
        self.protein = 0
        self.carbs = 0
        self.fats = 0
        self.detectedFrames = 0
        self.areaScore = 0.0
    }
}
