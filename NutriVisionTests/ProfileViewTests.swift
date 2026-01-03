////
////  ProfileViewTests.swift
////  NutriVision
////
////  Created by Marco Ferreira on 02/01/2026.
////
//
//import XCTest
//import SwiftUI
//import ViewInspector
//@testable import NutriVision
//
//final class ProfileViewTests: XCTestCase {
//    
//    var appState: AppState!
//    var user: User!
//    var vm: ProfileViewModel!
//    var view: ProfileView!
//    
//    override func setUp() async throws {
//        try await super.setUp()
//        await MainActor.run {
//            appState = AppState()
//            user = User(
//                id: "123",
//                name: "Test User",
//                email: "test@example.com",
//                age: 25,
//                height: 175,
//                weight: 70,
//                gender: .male,
//                weightGoal: .maintain,
//                dailyCalories: 2200
//            )
//            
//            vm = ProfileViewModel(user: user)
//            view = ProfileView(vm: vm)
//                .environmentObject(appState)
//        }
//    }
//    
//    override func tearDown() {
//        view = nil
//        vm = nil
//        user = nil
//        appState = nil
//        super.tearDown()
//    }
//    
//    func testProfileHeaderShowsUserInfo() throws {
//        let header = try view.inspect().scrollView().vStack().vStack(0)
//        let nameText = try header.text(1).string()
//        let emailText = try header.text(2).string()
//        XCTAssertEqual(nameText, "Test User")
//        XCTAssertEqual(emailText, "test@example.com")
//    }
//    
//    func testEditProfileButtonSwitchesToEditingMode() throws {
//        XCTAssertFalse(vm.isEditing)
//        let button = try view.inspect().scrollView().vStack().vStack(1).button(1)
//        try button.tap()
//        XCTAssertTrue(vm.isEditing)
//        XCTAssertEqual(vm.editName, "Test User")
//        XCTAssertEqual(vm.editAge, "25")
//        XCTAssertEqual(vm.editHeight, "175")
//        XCTAssertEqual(vm.editWeight, "70.0")
//    }
//    
//    func testCancelEditingResetsEditingState() throws {
//        vm.isEditing = true
//        vm.cancelEditing()
//        XCTAssertFalse(vm.isEditing)
//    }
//    
//    func testDailyCaloriesCalculationMaintain() throws {
//        vm.editWeight = "70"
//        vm.editHeight = "175"
//        vm.editAge = "25"
//        vm.editGender = .male
//        vm.editWeightGoal = .maintain
//        let calories = vm.calculateDailyCalories()
//        XCTAssertEqual(calories, 10*70 + 6.25*175 - 5*25 + 5)
//    }
//    
//    func testDailyCaloriesCalculationLose() throws {
//        vm.editWeightGoal = .lose
//        let calories = vm.calculateDailyCalories()
//        XCTAssertEqual(calories, (10*70 + 6.25*175 - 5*25 + 5) - 500)
//    }
//    
//    func testDailyCaloriesCalculationGain() throws {
//        vm.editWeightGoal = .gain
//        let calories = vm.calculateDailyCalories()
//        XCTAssertEqual(calories, (10*70 + 6.25*175 - 5*25 + 5) + 500)
//    }
//    
//    func testProfileInfoRowsDisplayCorrectValues() throws {
//        vm.isEditing = false
//        let infoRows = try view.inspect().scrollView().vStack().vStack(1)
//        let nameRow = try infoRows.find(ProfileInfoRow.self, where: { row in
//            try row.text(1).string() == "Test User"
//        })
//        XCTAssertNotNil(nameRow)
//    }
//}
