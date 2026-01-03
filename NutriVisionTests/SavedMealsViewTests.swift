//
//  SavedMealsViewTests.swift
//  NutriVision
//
//  Created by Marco Ferreira on 02/01/2026.
//

import XCTest
import SwiftUI
import ViewInspector
@testable import NutriVision

final class SavedMealsViewTests: XCTestCase {
    
    func testLoadingStateShowsProgressView() throws {
        let view = SavedMealsView(isLoading: true)
        let inspection = try view.inspect()

        XCTAssertNoThrow(
            try inspection
                .find(ViewType.ZStack.self)
                .find(ViewType.VStack.self, where: { _ in true })
                .find(ViewType.ProgressView.self)
        )
    }

    func testEmptyMealsShowsEmptyMealsView() throws {
        let view = SavedMealsView(filteredMeals: [], isLoading: false)
        let inspection = try view.inspect()
        
        let emptyView = try inspection
            .find(ViewType.ZStack.self)
            .find(ViewType.VStack.self, where: { _ in true })
            .find(EmptyMealsView.self)
            .actualView()
        
        XCTAssertNotNil(emptyView)
    }
}
