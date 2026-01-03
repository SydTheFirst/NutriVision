//
//  ProfileSetupViewModelTests.swift
//  NutriVision
//
//  Created by Marco Ferreira on 03/01/2026.
//

import XCTest
@testable import NutriVision

final class ProfileSetupViewModelTests: XCTestCase {
    
    // MARK: - Form Validation Tests
    func testFormValidation_EmptyFields() {
        let vm = ProfileSetupViewModel()
        XCTAssertFalse(vm.isFormValid)
    }
    
    func testFormValidation_InvalidNumbers() {
        let vm = ProfileSetupViewModel()
        vm.name = "John"
        vm.age = "abc"
        vm.height = "170"
        vm.weight = "70"
        XCTAssertFalse(vm.isFormValid)
        
        vm.age = "30"
        vm.weight = "xyz"
        XCTAssertFalse(vm.isFormValid)
    }
    
    func testFormValidation_ValidInputs() {
        let vm = ProfileSetupViewModel()
        vm.name = "John"
        vm.age = "30"
        vm.height = "170"
        vm.weight = "70"
        XCTAssertTrue(vm.isFormValid)
    }
    
    // MARK: - Daily Calories Calculation
    func testCalculateDailyCalories_MaleMaintain() {
        let vm = ProfileSetupViewModel()
        vm.gender = .male
        vm.weightGoal = .maintain
        vm.weight = "70"
        vm.height = "170"
        vm.age = "30"
        
        let weight = 70.0
        let height = 170.0
        let age = 30.0
        let expectedBMR = 10*weight + 6.25*height - 5*age + 5
        
        XCTAssertEqual(vm.calculateDailyCalories(), expectedBMR)
    }
    
    func testCalculateDailyCalories_FemaleLose() {
        let vm = ProfileSetupViewModel()
        vm.gender = .female
        vm.weightGoal = .lose
        vm.weight = "60"
        vm.height = "165"
        vm.age = "25"
        
        let weight = 60.0
        let height = 165.0
        let age = 25.0
        let bmr = 10*weight + 6.25*height - 5*age - 161
        
        XCTAssertEqual(vm.calculateDailyCalories(), bmr - 500)
    }
    
    func testCalculateDailyCalories_OtherGain() {
        let vm = ProfileSetupViewModel()
        vm.gender = .other
        vm.weightGoal = .gain
        vm.weight = "80"
        vm.height = "180"
        vm.age = "40"
        
        let weight = 80.0
        let height = 180.0
        let age = 40.0
        let bmr = 10*weight + 6.25*height - 5*age
        
        XCTAssertEqual(vm.calculateDailyCalories(), bmr + 500)
    }
    
    func testHandleCancel_NoUserCredential_DoesNotShowAlert() {
        let vm = ProfileSetupViewModel(userCredential: nil)
        vm.handleCancel()
        XCTAssertFalse(vm.showCancelAlert)
    }
}
