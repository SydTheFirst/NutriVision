//
//  RecordingViewTests.swift
//  NutriVision
//
//  Created by Marco Ferreira on 02/01/2026.
//

import XCTest
import SwiftUI
import ViewInspector
@testable import NutriVision

// MARK: - DataManager Mock
final class DataManagerMock: DataManager {
    override func getDailyCalorieGoal() -> Double {
        2000
    }

    override func fetchTodayCalories() {
        self.todayCalories = 500 // Simulate calories already logged
    }
}

// MARK: - NutritionService Mock
final class NutritionServiceMock: NutritionService {
    override func fetchNutrition(for query: String) async throws -> Ingredient? {
        var ingredient = Ingredient(
            name: query,
            amount: 100,
            unit: "g",
            calories: 100,
            protein: 5,
            carbs: 20,
            fats: 2
        )
        ingredient.areaScore = 10
        return ingredient
    }
}

@MainActor
final class RecordingViewTests: XCTestCase {

    var vm: RecordingViewModel!

    override func setUp() {
        super.setUp()
        vm = RecordingViewModel(dataManager: DataManagerMock(), nutritionService: NutritionServiceMock())
    }

    override func tearDown() {
        vm = nil
        super.tearDown()
    }

    func testInitialState() {
        XCTAssertTrue(vm.isScanning)
        XCTAssertTrue(vm.detectedIngredients.isEmpty)
        XCTAssertEqual(vm.mealName, "")
        XCTAssertFalse(vm.showNamingAlert)
        XCTAssertFalse(vm.showAddTodayAlert)
    }

    func testCalorieTotalsUpdateWhenIngredientAdded() {
        let ingredient = Ingredient(
            name: "Apple",
            amount: 1,
            unit: "serving",
            calories: 100,
            protein: 0.5,
            carbs: 25,
            fats: 0.2
        )
        vm.detectedIngredients.append(ingredient)

        XCTAssertEqual(vm.totalCalories, 100)
        XCTAssertEqual(vm.totalProtein, 0.5)
        XCTAssertEqual(vm.totalCarbs, 25)
        XCTAssertEqual(vm.totalFats, 0.2)
    }

    func testCalorieProgress() {
        let ingredient = Ingredient(
            name: "Banana",
            amount: 1,
            unit: "serving",
            calories: 200,
            protein: 1,
            carbs: 50,
            fats: 0.5
        )
        vm.detectedIngredients = [ingredient]
        vm.todayCalories = 0

        XCTAssertTrue(vm.calorieProgress > 0)
        XCTAssertLessThanOrEqual(vm.calorieProgress, 1.0)
    }

    func testSimulateDetectionAddsIngredient() async {
        let initialCount = vm.detectedIngredients.count
        vm.simulateDetection(name: "Pizza", grams: 200)

        // Wait briefly for async Task
        try? await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(vm.detectedIngredients.count, initialCount + 1)
        XCTAssertTrue(vm.detectedIngredients.contains(where: { $0.name == "200g Pizza" }))
    }

    func testStartSaveMealSetsNamingAlert() {
        vm.startSaveMeal()
        XCTAssertFalse(vm.isScanning)
        XCTAssertTrue(vm.showNamingAlert)
    }

    func testStartAddToTodaySetsAddTodayAlert() {
        vm.startAddToToday()
        XCTAssertFalse(vm.isScanning)
        XCTAssertTrue(vm.showAddTodayAlert)
    }

    func testCancelNamingResetsState() {
        vm.mealName = "Test Meal"
        vm.isScanning = false
        vm.cancelNaming()

        XCTAssertEqual(vm.mealName, "")
        XCTAssertTrue(vm.isScanning)
    }

    func testDeleteIngredientFromDetectedList() {
        let apple = Ingredient(
            name: "Apple",
            amount: 1,
            unit: "serving",
            calories: 100,
            protein: 1,
            carbs: 25,
            fats: 0.2
        )
        let egg = Ingredient(
            name: "Egg",
            amount: 1,
            unit: "serving",
            calories: 70,
            protein: 6,
            carbs: 0.5,
            fats: 5
        )
        vm.detectedIngredients = [apple, egg]

        vm.deleteIngredient(apple)

        XCTAssertEqual(vm.detectedIngredients.count, 1)
        XCTAssertFalse(vm.detectedIngredients.contains(where: { $0.name == "Apple" }))
        XCTAssertTrue(vm.detectedIngredients.contains(where: { $0.name == "Egg" }))
    }

    func testMealNameAlertShows() {
        vm.showNamingAlert = true
        XCTAssertTrue(vm.showNamingAlert)
    }

    func testAddToTodayAlertShows() {
        vm.showAddTodayAlert = true
        XCTAssertTrue(vm.showAddTodayAlert)
    }

    func testTotalIngredientAreaScore() {
        var ingredient1 = Ingredient(aiDetectedName: "Apple")
        ingredient1.areaScore = 10

        var ingredient2 = Ingredient(aiDetectedName: "Banana")
        ingredient2.areaScore = 15

        vm.detectedIngredients = [ingredient1, ingredient2]

        XCTAssertEqual(vm.totalIngredientAreaScore, 25)
    }
}
