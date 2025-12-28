//
//  SharedComponents.swift
//  NutriVision
//
//  Created by Vasco Zambujo on 27/12/2025.
//

import SwiftUI

// Move this to SharedComponents.swift
struct IngredientRow: View {
    let ingredient: Ingredient
    
    var body: some View {
        HStack(spacing: 12) {
            // The blue dot from your design
            Circle()
                .fill(Color.gray.opacity(0.5))
                .frame(width: 6, height: 6)
            
            Text(ingredient.name)
                .font(.body.weight(.medium))
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                // Displays "100 g" or "1 serving"
                Text(ingredient.formattedAmount)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Matches the orange flame icon in your screenshot
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    Text("\(Int(ingredient.calories)) kcal")
                        .font(.caption.bold())
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        // Light shadow to match your cards
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// Also move your SummaryPill here so it's reusable!
struct SummaryPill: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.headline)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 2)
    }
}
