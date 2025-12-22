//
//  RootView.swift
//  NutriVision
//
//  Created by Vasco Zambujo on 22/12/2025.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        if !appState.isLoggedIn {
            AuthView()
        } else if appState.needsProfileSetup {
            ProfileSetupView(
                email: appState.email ?? "",
                userCredential: nil,
                onProfileComplete: {
                    appState.needsProfileSetup = false
                },
                onCancel: {
                    appState.logout()
                }
            )
        } else {
            HomeView()
        }
    }
}

