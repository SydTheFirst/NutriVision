//
//  DetectedIngredientRow.swift
//  NutriVision
//
//  Created by Marco Ferreira on 30/12/2025.
//


import SwiftUI

struct DetectedIngredientRow: View {
    let ingredient: Ingredient

    var body: some View {
        HStack(spacing: 12) {

            // Icon
            Image(systemName: "leaf.fill")
                .foregroundColor(.green)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(ingredient.name)
                    .font(.headline)

                Text(ingredient.formattedAmount)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(ingredient.calories)) kcal")
                    .font(.headline)

                Text(
                    "P \(Int(ingredient.protein))g  •  C \(Int(ingredient.carbs))g  •  F \(Int(ingredient.fats))g"
                )
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}
