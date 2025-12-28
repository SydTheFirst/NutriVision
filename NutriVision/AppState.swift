//
//  AppState.swift
//  NutriVision
//
//  Created by Vasco Zambujo on 22/12/2025.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class AppState: ObservableObject {
    @Published var isLoggedIn = false
    @Published var needsProfileSetup = false
    @Published var email: String?
    


    func loadInitialState() {
        guard let user = Auth.auth().currentUser else {
            isLoggedIn = false
            return
        }

        email = user.email
        isLoggedIn = true

        Firestore.firestore()
            .collection("Users")
            .document(user.uid)
            .getDocument { snapshot, _ in
                let completed = snapshot?.data()?["profileCompleted"] as? Bool ?? false
                self.needsProfileSetup = !completed
            }
    }

    func logout() {
        try? Auth.auth().signOut()
        isLoggedIn = false
        needsProfileSetup = false
        email = nil
    }
}
