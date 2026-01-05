//
//  NutritionService.swift
//  NutriVision
//
//  Created by Vasco Zambujo on 30/12/2025.
//

import Foundation

class NutritionService {
    
    private let session: URLSession
    private let appId: String
    private let appKey: String

    private static var lastGlobalCallTime: Date?
    private static let minInterval: TimeInterval = 6.5 // ~9 calls per minute

    init(appId: String = "51ff2ea1",
        appKey: String = "9a22bafc11a8098a6d547f809b6bf3ec",
        session: URLSession = .shared) {
        self.appId = appId
        self.appKey = appKey
        self.session = session
    }

    func fetchNutrition(for query: String) async throws -> Ingredient? {
        // --- GLOBAL SAFETY LIMITER ---
        if let lastCall = NutritionService.lastGlobalCallTime,
           Date().timeIntervalSince(lastCall) < NutritionService.minInterval {
            print("SAFETY: Global rate limit protection triggered. Request for [\(query)] blocked.")
            return nil
        }
        NutritionService.lastGlobalCallTime = Date()
        // -----------------------------

        print("API: Fetching for [\(query)]")   
        guard let url = url(for: query) else { return nil }

        let (data, response) = try await session.data(from: url)
        
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 429 {
                print("API: Rate Limit Exceeded (429).")
                return nil
            }
            print("HTTP Status: \(httpResponse.statusCode)")
        }

        let decoded = try JSONDecoder().decode(EdamamResponse.self, from: data)
        let nutrients = decoded.firstParsedNutrients
        
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
    
    static func setLastCallTime(_ date: Date?) {
        lastGlobalCallTime = date
    }

    private func url(for query: String) -> URL? {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "https://api.edamam.com/api/nutrition-data?app_id=\(appId)&app_key=\(appKey)&ingr=\(encoded)"
        return URL(string: urlString)
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
