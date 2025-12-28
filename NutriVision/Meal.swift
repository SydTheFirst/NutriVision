//
//  Meal.swift
//  NutriVision
//
//  Created by Vasco Zambujo on 26/12/2025.
//

import SwiftUI
import FirebaseFirestore

struct Meal: Identifiable, Equatable, Codable {
    @DocumentID var id: String?  // This automatically captures the Firestore Document ID
    var userID: String?
    var name: String
    var date: Date = Date()
    var isSaved: Bool?
    var ingredients: [Ingredient]
    
    // Totals
    var calories: Double
    var protein: Double
    var carbs: Double
    var fats: Double

    // This enum tells Swift which fields to look for in the JSON/Firestore
    enum CodingKeys: String, CodingKey {
        case id         // Must be here
        case userID
        case name
        case date
        case isSaved
        case ingredients
        case calories
        case protein
        case carbs
        case fats
    }

    // Default initializer for manual creation (like when AI generates a meal)
    init(id: String? = nil, userID: String? = nil, name: String, date: Date = Date(), isSaved: Bool? = false, ingredients: [Ingredient]) {
        self.id = id
        self.userID = userID
        self.name = name
        self.date = date
        self.isSaved = isSaved
        self.ingredients = ingredients
        
        // Auto-calculate totals from ingredients
        self.calories = ingredients.reduce(0) { $0 + $1.calories }
        self.protein = ingredients.reduce(0) { $0 + $1.protein }
        self.carbs = ingredients.reduce(0) { $0 + $1.carbs }
        self.fats = ingredients.reduce(0) { $0 + $1.fats }
    }

    // Custom Decoder to handle Firestore and AI JSON safely
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode ID, userID, and isSaved as optional
        self.id = try container.decodeIfPresent(String.self, forKey: .id)
        self.userID = try container.decodeIfPresent(String.self, forKey: .userID)
        self.isSaved = try container.decodeIfPresent(Bool.self, forKey: .isSaved) ?? false
        
        // Decode core fields
        self.name = try container.decode(String.self, forKey: .name)
        
        // Decode date or default to now
        self.date = try container.decodeIfPresent(Date.self, forKey: .date) ?? Date()
        
        // Decode ingredients
        self.ingredients = try container.decode([Ingredient].self, forKey: .ingredients)
        
        // Replace the current protein/calories/etc lines with this:
        self.calories = try container.decodeIfPresent(Double.self, forKey: .calories) ?? 0.0
        self.protein = try container.decodeIfPresent(Double.self, forKey: .protein) ?? 0.0
        self.carbs = try container.decodeIfPresent(Double.self, forKey: .carbs) ?? 0.0
        self.fats = try container.decodeIfPresent(Double.self, forKey: .fats) ?? 0.0
    }
}
