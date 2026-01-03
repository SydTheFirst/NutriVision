//
//  DashboardStatsViewTests.swift
//  NutriVision
//
//  Created by Marco Ferreira on 02/01/2026.
//


import XCTest
import SwiftUI
import ViewInspector
@testable import NutriVision

final class DashboardStatsViewTests: XCTestCase {
    
    class MockNutritionVM: NutritionViewModel {
        var fetchCalled = 0
        override func fetchData(for span: TimeSpan, macro: MacroType) {
            fetchCalled += 1
        }
    }
    
    func testOnAppearCallsFetch() throws {
        let mockVM = MockNutritionVM()
        let view = DashboardStatsView(vm: mockVM)

        // Simulate onAppear
        try view.inspect().vStack().callOnAppear()

        XCTAssertEqual(mockVM.fetchCalled, 1)
    }
    
    func testPickerChangeCallsFetch() throws {
        let mockVM = MockNutritionVM()
        let view = DashboardStatsView(vm: mockVM, initialTimeSpan: .daily)
        
        let inspection = try view.inspect()
        
        // Simulate picker change to weekly
        try inspection.vStack().picker(0).select(value: TimeSpan.weekly)
        
        XCTAssertGreaterThanOrEqual(mockVM.fetchCalled, 1)
    }
    
    func testLoadedStateShowsChartView() throws {
        let mockVM = MockNutritionVM()
        mockVM.isLoading = false
        mockVM.nutritionData = [NutritionData(date: Date(), value: 100)]
        
        let view = DashboardStatsView(vm: mockVM)
        let inspection = try view.inspect()
        
        // Check that ChartView exists
        XCTAssertNoThrow(
            try inspection.vStack().view(ChartView.self, 1)
        )
    }
}
