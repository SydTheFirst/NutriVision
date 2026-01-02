//
//  UserInfo.swift
//  NutriVision
//
//  Created by Vasco Zambujo on 22/12/2025.
//

import SwiftUI

struct User: Identifiable{
    let id: String?
    let name: String
    let email: String
    let age: Int?
    let height: Int?
    let weight: Double?
    let gender: Gender?
    let weightGoal: WeightGoal?
    let dailyCalories: Double?  // Calculated based on user profile
}

enum Gender: String, Codable, CaseIterable {
    case male, female, other
}

enum WeightGoal: String, Codable, CaseIterable {
    case lose, maintain, gain
}
