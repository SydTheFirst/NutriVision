//
//  FirestoreMealRepository.swift
//  NutriVision
//
//  Created by Marco Ferreira on 03/01/2026.
//

import FirebaseFirestore

final class FirestoreMealRepository: MealRepository {
    func renameMeal(userID: String, mealID: String, newName: String) {
        Firestore.firestore()
            .collection("Users")
            .document(userID)
            .collection("Meals")
            .document(mealID)
            .updateData([
                "name": newName,
                "isSaved": true
            ])
    }
}
