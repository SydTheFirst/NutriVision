//
//  HomeViewTests.swift
//  NutriVision
//
//  Created by Marco Ferreira on 02/01/2026.
//

import XCTest
import SwiftUI
import ViewInspector
@testable import NutriVision

final class HomeViewTests: XCTestCase {

    var appState: AppState!

    override func setUp() async throws {
        try await super.setUp()
        await MainActor.run {
            appState = AppState()
        }
    }

    override func tearDown() async throws {
        await MainActor.run {
            appState = nil
        }
        try await super.tearDown()
    }

    // MARK: - Helpers

    /// Generates the view for inspection with environment injected
    private func makeView() -> some View {
        HomeView().environmentObject(appState)
    }

    // MARK: - Tests

    func testLoginRegisterButtonShownWhenLoggedOut() async throws {
        await MainActor.run {
            appState.isLoggedIn = false
        }

        let view = makeView()
        let inspected = try view.inspect()

        let button = try inspected.find(HomeActionButton.self, where: { button in
            try button.vStack().text(0).string() == "Login / Register"
        })
        XCTAssertNotNil(button, "Login/Register button should appear when logged out")
    }

    func testProfileButtonAppearsInToolbarWhenLoggedIn() async throws {
        await MainActor.run {
            appState.isLoggedIn = true
        }

        let view = makeView()
        let inspected = try view.inspect()
        let toolbarButton = try inspected.navigationStack().toolbar().find(button: "person.crop.circle.fill")
        XCTAssertNotNil(toolbarButton)
    }

    func testHomeActionButtonLayout() throws {
        let button = HomeActionButton(
            icon: "record.circle.fill",
            title: "Start Recording",
            subtitle: "Scan your meal",
            color: .blue
        )
        let inspected = try button.inspect()
        let text = try inspected.hStack().vStack(1).text(0).string()
        XCTAssertEqual(text, "Start Recording")
        let subtitle = try inspected.hStack().vStack(1).text(1).string()
        XCTAssertEqual(subtitle, "Scan your meal")
    }

    func testBackgroundColorChangesWithColorScheme() throws {
        let view = makeView()
        let inspected = try view.inspect()
        let color = try inspected.zStack().color(0)
        XCTAssertNotNil(color)
    }

    func testNavigationLinksExist() throws {
        let view = makeView()
        let inspected = try view.inspect()

        let navLinks = try inspected.findAll(ViewType.NavigationLink.self)

        let titles = try navLinks.map { link -> String in
            let button = try link.labelView().find(HomeActionButton.self)
            return try button.vStack().text(0).string()
        }

        XCTAssertTrue(titles.contains("Start Recording"))
    }
}
