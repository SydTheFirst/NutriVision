//
//  MealRepository.swift
//  NutriVision
//
//  Created by Marco Ferreira on 03/01/2026.
//


protocol MealRepository {
    func renameMeal(userID: String, mealID: String, newName: String)
}
