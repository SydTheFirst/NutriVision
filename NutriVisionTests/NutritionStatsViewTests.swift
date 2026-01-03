//
//  NutritionStatsViewTests.swift
//  NutriVision
//
//  Created by Marco Ferreira on 02/01/2026.
//

import XCTest
import SwiftUI
import ViewInspector
@testable import NutriVision

final class NutritionStatsViewTests: XCTestCase {
    
    
    // MARK: - Mock ViewModel
    final class MockNutritionViewModel: NutritionViewModelProtocol {
        @Published var nutritionData: [NutritionData] = []
        @Published var isLoading: Bool = false

        var averageValue: Double = 100
        var totalValue: Double = 500
        var highestValue: Double = 200

        func fetchData(for timeSpan: TimeSpan, macro: MacroType) {
            // no-op
        }
    }
    
    func makeView(vm: MockNutritionViewModel = MockNutritionViewModel())
    -> NutritionStatsView<MockNutritionViewModel> {
        NutritionStatsView(vm: vm)
    }
    
    // MARK: - Tests
    
    func testProgressViewAppearsWhenLoading() throws {
        let vm = MockNutritionViewModel()
        vm.isLoading = true
        let view = makeView(vm: vm)
        let progress = try view.inspect()
            .scrollView()
            .vStack()
            .vStack(2)
            .progressView(0)

        XCTAssertNotNil(progress)
    }
    
    func testEmptyStateViewAppearsWhenNoData() throws {
        let vm = MockNutritionViewModel()
        vm.nutritionData = []
        let view = makeView(vm: vm)
        let emptyView = try view.inspect().scrollView().vStack().vStack(2).view(EmptyStateView.self, 0)
        XCTAssertNotNil(emptyView)
    }
    
    func testChartViewAppearsWithData() throws {
        let vm = MockNutritionViewModel()
        vm.nutritionData = [
            NutritionData(date: Date(), value: 100),
            NutritionData(date: Date().addingTimeInterval(86400), value: 200)
        ]
        let view = makeView(vm: vm)
        let chart = try view.inspect().scrollView().vStack().vStack(2).view(ChartView.self, 0)
        XCTAssertNotNil(chart)
    }
    
    func testTimeSpanSelectionUpdatesState_UI() throws {
        let vm = MockNutritionViewModel()
        let view = makeView(vm: vm)

        let hStack = try view.inspect()
            .scrollView()
            .vStack()
            .vStack(0)
            .hStack(0)

        let weeklyButton = try hStack.button(1)
        try weeklyButton.tap()

        let fgColor = try weeklyButton.labelView().foregroundColor()
        XCTAssertEqual(fgColor, .accentColor, "Weekly button should appear selected")
    }
    
    func testMacroTypeSelectionUpdatesState_UI() throws {
        let vm = MockNutritionViewModel()
        let view = makeView(vm: vm)

        // Tap the "protein" button (index 1)
        let grid = try view.inspect()
            .scrollView()
            .vStack()
            .vStack(1)
            .lazyVGrid(0) // grid itself

        let buttons = try grid.forEach(0) // access items inside LazyVGrid
        let proteinButton = try buttons.button(1)
        try proteinButton.tap()

        // Assert: "protein" button visually selected by checking foreground color
        let fgColor = try proteinButton.labelView().foregroundColor()
        XCTAssertEqual(fgColor, Color.accentColor)
    }
    
    func testSummaryCardsShowCorrectValues() throws {
        let vm = MockNutritionViewModel()
        let view = makeView(vm: vm)
        
        let hStack = try view.inspect().scrollView().vStack().hStack(2)
        
        let avgCard = try hStack.view(SummaryCard.self, 0).actualView()
        XCTAssertEqual(avgCard.value, "100")
        
        let totalCard = try hStack.view(SummaryCard.self, 1).actualView()
        XCTAssertEqual(totalCard.value, "500")
        
        let maxCard = try hStack.view(SummaryCard.self, 2).actualView()
        XCTAssertEqual(maxCard.value, "200")
    }
}
