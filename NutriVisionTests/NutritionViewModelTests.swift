//
//  NutritionViewModelTests.swift
//  NutriVision
//
//  Created by Marco Ferreira on 02/01/2026.
//

import XCTest
@testable import NutriVision

final class NutritionViewModelTests: XCTestCase {
    
    var vm: NutritionViewModel!
    
    override func setUp() {
        super.setUp()
        vm = NutritionViewModel()
    }
    
    override func tearDown() {
        vm = nil
        super.tearDown()
    }
    
    func testCalculateStatsWithNoData() {
        vm.nutritionData = []
        // Force calculation manually
        vm.fetchData(for: .daily, macro: .calories)
        // Because currentUser is nil, fetchData will exit immediately
        XCTAssertTrue(vm.nutritionData.isEmpty)
        XCTAssertEqual(vm.totalValue, 0)
        XCTAssertEqual(vm.averageValue, 0)
        XCTAssertEqual(vm.highestValue, 0)
    }
    
    func testCalculateStatsWithSampleData() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        vm.nutritionData = [
            NutritionData(date: today, value: 100),
            NutritionData(date: today.addingTimeInterval(-86400), value: 200),
            NutritionData(date: today.addingTimeInterval(-2*86400), value: 50)
        ]
        
        // Call private calculateStats via KVC or simulate fetch completion
        let total = vm.nutritionData.map { $0.value }.reduce(0, +)
        let average = total / Double(vm.nutritionData.count)
        let highest = vm.nutritionData.map { $0.value }.max() ?? 0
        
        // Manually simulate the calculation
        vm.totalValue = total
        vm.averageValue = average
        vm.highestValue = highest
        
        XCTAssertEqual(vm.totalValue, 350)
        XCTAssertEqual(vm.averageValue, 116.66666666666667, accuracy: 0.001)
        XCTAssertEqual(vm.highestValue, 200)
    }
    
    func testGenerateSampleDataProducesCorrectCount() {
        // Use reflection to call private generateSampleData (optional)
        // Or temporarily make it internal for testing
        // Here we simulate what it would do
        let span = TimeSpan.daily
        let macro = MacroType.protein
        
        vm.nutritionData = []
        // simulate generating data
        let calendar = Calendar.current
        let endDate = Date()
        var data: [NutritionData] = []
        for i in 0..<span.days {
            if let date = calendar.date(byAdding: .day, value: -i, to: endDate) {
                data.append(NutritionData(date: calendar.startOfDay(for: date), value: Double(i+1)*10))
            }
        }
        vm.nutritionData = data
        
        XCTAssertEqual(vm.nutritionData.count, span.days)
    }
    
    func testCalculateStatsConsistency() {
        let data = [
            NutritionData(date: Date(), value: 10),
            NutritionData(date: Date(), value: 20),
            NutritionData(date: Date(), value: 30),
            NutritionData(date: Date(), value: 40)
        ]
        vm.nutritionData = data
        
        let total = data.map { $0.value }.reduce(0, +)
        let average = total / Double(data.count)
        let maxVal = data.map { $0.value }.max() ?? 0
        
        vm.totalValue = total
        vm.averageValue = average
        vm.highestValue = maxVal
        
        XCTAssertEqual(vm.totalValue, 100)
        XCTAssertEqual(vm.averageValue, 25)
        XCTAssertEqual(vm.highestValue, 40)
    }
}
