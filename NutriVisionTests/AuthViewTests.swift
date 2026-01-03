//
//  AuthViewTests.swift
//  NutriVision
//
//  Created by Marco Ferreira on 02/01/2026.
//

import XCTest
import SwiftUI
import ViewInspector
@testable import NutriVision

// MARK: - Make views inspectable
extension AuthView: Inspectable {}
extension SegmentedView: Inspectable {}
extension BottomView: Inspectable {}

final class AuthViewTests: XCTestCase {

    var appState: AppState!

    // MARK: - Setup / Teardown
    override func setUp() {
        super.setUp()
        appState = AppState()
    }

    override func tearDown() {
        appState = nil
        super.tearDown()
    }

    // MARK: - Helper to create view with environment object
    private func makeView() -> AuthView {
        AuthView().environmentObject(appState)
    }

    // MARK: - Tests

    func testLoginButtonDisabledWhenEmpty() throws {
        let view = makeView()
        let button = try view.inspect().find(button: "Login")
        XCTAssertTrue(try button.isDisabled(), "Login button should be disabled when email/password are empty")
    }

    func testRegisterButtonDisabledWhenEmpty() throws {
        let view = makeView()
        // Switch authType to register
        try view.inspect().find(SegmentedView.self).callOnTapGesture(at: 1)
        let button = try view.inspect().find(button: "Register")
        XCTAssertTrue(try button.isDisabled(), "Register button should be disabled when email/password are empty")
    }

    func testAuthTypeSwitchingUpdatesButtonText() throws {
        let view = makeView()
        var button = try view.inspect().find(button: "Login")
        XCTAssertEqual(try button.labelView().text().string(), "Login")

        // Switch to Register
        try view.inspect().find(SegmentedView.self).callOnTapGesture(at: 1)
        button = try view.inspect().find(button: "Register")
        XCTAssertEqual(try button.labelView().text().string(), "Register")
    }

    func testEmailPasswordBinding() throws {
        let view = makeView()
        let emailField = try view.inspect().find(ViewType.TextField.self, where: { tf in
            try tf.placeholder() == "Email"
        })
        try emailField.setInput("test@example.com")
        XCTAssertEqual(try emailField.input(), "test@example.com")

        let passwordField = try view.inspect().find(ViewType.SecureField.self)
        try passwordField.setInput("123456")
        XCTAssertEqual(try passwordField.input(), "123456")
    }

    func testPasswordToggleShowsTextField() throws {
        let view = makeView()
        let zstack = try view.inspect().find(ViewType.ZStack.self, where: { z in
            z.content.viewCount == 2
        })
        let overlayButton = try zstack.button(1)
        XCTAssertNoThrow(try overlayButton.tap())
    }

    func testAlertShowsWhenStateSet() throws {
        let view = makeView()
        // Simulate alert state
        view.showAlert = true
        view.alertMessage = "Test Error"

        let alert = try view.inspect().find(ViewType.Alert.self)
        XCTAssertEqual(try alert.title().string(), "Error")
        XCTAssertEqual(try alert.message().text().string(), "Test Error")
    }

    func testGoToProfileSetupNavigation() throws {
        let view = makeView()
        view.goToProfileSetup = true
        XCTAssertTrue(view.goToProfileSetup, "Navigation to ProfileSetup should be triggered")
    }

    func testBottomViewGoogleActionCalled() throws {
        let view = makeView()
        var called = false
        let bottom = try view.inspect().find(BottomView.self)
        try bottom.actualView().googleAction()
        called = true
        XCTAssertTrue(called, "Google Action callback should be callable")
    }
}
