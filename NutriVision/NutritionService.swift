//
//  NutritionService.swift
//  NutriVision
//
//  Created by Vasco Zambujo on 30/12/2025.
//

import Foundation

class NutritionService {
    let appId = "51ff2ea1"
    let appKey = "9a22bafc11a8098a6d547f809b6bf3ec"
    
    func fetchNutrition(for query: String) async throws -> Ingredient? {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "https://api.edamam.com/api/nutrition-data?app_id=\(appId)&app_key=\(appKey)&ingr=\(encodedQuery)"
        
        guard let url = URL(string: urlString) else { return nil }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let response = try JSONDecoder().decode(EdamamResponse.self, from: data)
        
        // Extract nutrients from the nested path
        let nutrients = response.firstParsedNutrients
        
        // Edamam uses these specific codes:
        // Calories: ENERC_KCAL
        // Protein: PROCNT
        // Carbs: CHOCDF
        // Fats: FAT
        return Ingredient(
            name: query,
            amount: 1,
            unit: "serving",
            calories: nutrients?["ENERC_KCAL"]?.quantity ?? 0,
            protein: nutrients?["PROCNT"]?.quantity ?? 0,
            carbs: nutrients?["CHOCDF"]?.quantity ?? 0,
            fats: nutrients?["FAT"]?.quantity ?? 0
        )
    }
}

struct EdamamResponse: Codable {
    let ingredients: [EdamamIngredient]?
    
    var firstParsedNutrients: [String: NutrientInfo]? {
        ingredients?.first?.parsed?.first?.nutrients
    }
}

struct EdamamIngredient: Codable {
    let parsed: [ParsedIngredient]?
}

struct ParsedIngredient: Codable {
    let nutrients: [String: NutrientInfo]?
}

struct NutrientInfo: Codable {
    let label: String?
    let quantity: Double?
    let unit: String?
}
