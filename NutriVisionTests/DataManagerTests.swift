//
//  DataManagerTests.swift
//  NutriVision
//
//  Created by Marco Ferreira on 02/01/2026.
//

import XCTest
@testable import NutriVision

final class DataManagerTests: XCTestCase {

    func testGetDailyCalorieGoal_Default() {
        let manager = DataManager()
        manager.currentUser = nil
        XCTAssertEqual(manager.getDailyCalorieGoal(), 2000, "Default daily calorie goal should be 2000 when currentUser is nil")
    }

    func testGetDailyCalorieGoal_FromUser() {
        let manager = DataManager()
        let user = User(
            id: "1",
            name: "",
            email: "",
            age: nil,
            height: nil,
            weight: nil,
            gender: nil,
            weightGoal: nil,
            dailyCalories: 1800
        )
        manager.currentUser = user
        XCTAssertEqual(manager.getDailyCalorieGoal(), 1800, "Daily calorie goal should come from currentUser if set")
    }
}
