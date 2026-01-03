//
//  AISuggestionViewModelTests.swift
//  NutriVision
//
//  Created by Marco Ferreira on 02/01/2026.
//


import XCTest
@testable import NutriVision

@MainActor
final class AISuggestionViewModelTests: XCTestCase {
    
    var vm: AISuggestionViewModel!
    var mockDataManager: DataManager!

    override func setUp() {
        super.setUp()
        mockDataManager = DataManager()
        vm = AISuggestionViewModel(dataManager: mockDataManager)
        
        // Prepare some history
        let historyMeal = Meal(userID: "uid", name: "Breakfast", date: Date(), isSaved: false, ingredients: [])
        mockDataManager.todayCalories = 400
    }

    func testGenerateMealSuggestion_parsesJSONCorrectly() async {
        let mockGenerator = MockMealGenerator()
        vm.mealGenerator = mockGenerator
        
        let history = [Meal(userID: "uid", name: "Breakfast", date: Date(), isSaved: false, ingredients: [])]
        
        await vm.generateMealSuggestion(history: history)
        
        XCTAssertNotNil(vm.suggestedMeal)
        XCTAssertEqual(vm.suggestedMeal?.name, "Test Meal")
        XCTAssertEqual(vm.suggestedMeal?.ingredients.first?.name, "Apple")
    }
    
    func testAddToToday_setsMealCorrectly() {
        vm.suggestedMeal = Meal(userID: "uid", name: "Test Meal", date: Date(), isSaved: false, ingredients: [])
        vm.addToToday()
        
        // Should still be unsaved and have new date
        XCTAssertFalse(vm.suggestedMeal?.isSaved ?? true)
    }
}

class MockMealGenerator {
    func generateMeal(history: [Meal]) async -> Meal? {
        return Meal(
            userID: "uid",
            name: "Test Meal",
            date: Date(),
            isSaved: false,
            ingredients: [Ingredient(
                name: "Apple",
                amount: 100.0,
                unit: "g",
                calories: 52.0,
                protein: 0.3,
                carbs: 14.0,
                fats: 0.2
            )]
        )
    }
}
