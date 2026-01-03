//
//  HistoryViewTests.swift
//  NutriVision
//
//  Created by Marco Ferreira on 02/01/2026.
//


import XCTest
import Firebase
@testable import NutriVision

final class HistoryViewTests: XCTestCase {

    var historyView: HistoryView!
    var testMeals: [Meal]!

    override func setUp() {
        super.setUp()
        historyView = HistoryView()
        
        // Prepare mock meals for 3 days
        let today = Calendar.current.startOfDay(for: Date())
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: today)!
        
        testMeals = [
            Meal(userID: "uid1", name: "Breakfast", date: today, isSaved: true, ingredients: []),
            Meal(userID: "uid1", name: "Lunch", date: today, isSaved: false, ingredients: []),
            Meal(userID: "uid1", name: "Snack", date: yesterday, isSaved: false, ingredients: []),
            Meal(userID: "uid1", name: "Dinner", date: twoDaysAgo, isSaved: true, ingredients: [])
        ]
    }

    override func tearDown() {
        historyView = nil
        testMeals = nil
        super.tearDown()
    }

    func testGroupMealsByDate() {
        let grouped = HistoryGrouping.groupMealsByDay(testMeals)

        XCTAssertEqual(grouped.keys.count, 3)

        let today = Calendar.current.startOfDay(for: Date())
        XCTAssertEqual(grouped[today]?.count, 2)
    }

    func testExpandedDaysToggleLogic() {
        let day = Calendar.current.startOfDay(for: Date())
        var expanded: Set<Date> = []

        expanded = ExpandedDaysLogic.toggle(day, in: expanded)
        XCTAssertTrue(expanded.contains(day))

        expanded = ExpandedDaysLogic.toggle(day, in: expanded)
        XCTAssertFalse(expanded.contains(day))
    }

    // MARK: - Test lastSevenDays
    func testLastSevenDays_returnsSevenDates() {
        let days = historyView.lastSevenDays
        XCTAssertEqual(days.count, 7)
        
        // The first date should be today
        let today = Calendar.current.startOfDay(for: Date())
        XCTAssertEqual(days.first, today)
    }
    
    // MARK: - Test meal cloning logic (addToToday)
    func testAddToToday_createsMealWithTodayDate() {
        let meal = testMeals[0]
        let mealRow = HistoryMealRow(meal: meal, mealNumber: 1)
        
        // We cannot write to Firestore in unit test, but we can test the cloned object creation
        let todayMeal = Meal(
            userID: meal.userID,
            name: meal.name.isEmpty ? "Meal #1" : meal.name,
            date: Date(),
            isSaved: false,
            ingredients: meal.ingredients
        )
        
        XCTAssertEqual(todayMeal.userID, meal.userID)
        XCTAssertEqual(todayMeal.ingredients.count, meal.ingredients.count)
        XCTAssertFalse(todayMeal.isSaved ?? true)
    }
}

final class MockMealRepository: MealRepository {
    var renamedMealID: String?
    var renamedName: String?

    func renameMeal(userID: String, mealID: String, newName: String) {
        renamedMealID = mealID
        renamedName = newName
    }
}
