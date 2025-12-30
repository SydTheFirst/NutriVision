//
//  DetectedIngredientRow.swift
//  NutriVision
//
//  Created by Marco Ferreira on 30/12/2025.
//


import SwiftUI

struct DetectedIngredientRow: View {
    let ingredient: Ingredient
    var onDelete: (() -> Void)? // callback when user taps trash
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.5))
                .frame(width: 6, height: 6)
            
            Text(ingredient.name)
                .font(.body.weight(.medium))
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(ingredient.formattedAmount)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    Text("\(Int(ingredient.calories)) kcal")
                        .font(.caption.bold())
                        .foregroundColor(.orange)
                }
                
                if ingredient.areaScore > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "ruler.fill")
                            .font(.caption2)
                            .foregroundColor(.blue)
                        Text(String(format: "%.1f cm²", ingredient.areaScore))
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            // Trash button
            Button(action: {
                onDelete?()
            }) {
                Image(systemName: "trash.fill")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
