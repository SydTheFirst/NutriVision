//
//  RecordingView.swift
//  NutriVision
//
//  Created by Vasco Zambujo on 27/12/2025.
//

import SwiftUI
import Firebase

struct RecordingView: View {
    @Environment(\.dismiss) var dismiss
    @State private var detectedIngredients: [Ingredient] = []
    
    // Naming alert state
    @State private var showNamingAlert = false
    @State private var showAddTodayAlert = false
    @State private var mealName: String = ""

    // Computed totals
    var totalCalories: Double { detectedIngredients.reduce(0) { $0 + $1.calories } }
    var totalProtein: Double { detectedIngredients.reduce(0) { $0 + $1.protein } }
    var totalCarbs: Double { detectedIngredients.reduce(0) { $0 + $1.carbs } }
    var totalFats: Double { detectedIngredients.reduce(0) { $0 + $1.fats } }
    
    var totalIngredientAreaScore: CGFloat {
        detectedIngredients.reduce(0) { $0 + $1.areaScore }
    }

    var body: some View {
        
        VStack(spacing: 0) {
            // 1. Camera Feed (30% Height)
            ZStack(alignment: .bottomTrailing) {
                ARCameraView(
                    detectedIngredients: $detectedIngredients,
                    calories: totalCalories,
                    protein: totalProtein,
                    carbs: totalCarbs,
                    fats: totalFats
                )
                .ignoresSafeArea()
                
                Text("AI ACTIVE")
                    .font(.caption2.bold())
                    .padding(6)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                    .padding()
            }
            .frame(height: UIScreen.main.bounds.height * 0.30)
            
            // 2. Nutrition Details Area
            VStack(spacing: 0) {
                // FIXED Horizontal Scroll
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 9) {
                        SummaryPill(title: "Calories", value: String(format: "%.0fkcal", totalCalories), icon: "flame.fill", color: .orange)
                        SummaryPill(title: "Protein", value: String(format: "%.1fg", totalProtein), icon: "leaf.fill", color: .green)
                        SummaryPill(title: "Carbs", value: String(format: "%.1fg", totalCarbs), icon: "bolt.fill", color: .purple)
                        SummaryPill(title: "Fats", value: String(format: "%.1fg", totalFats), icon: "drop.fill", color: .red)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 25)
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Detected Ingredients")
                            .font(.title3.bold())
                            .padding(.horizontal)

                        if detectedIngredients.isEmpty {
                            VStack(spacing: 10) {
                                ProgressView()
                                Text("Detecting ingredients...")
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 50)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(detectedIngredients) { ingredient in
                                    DetectedIngredientRow(
                                        ingredient: ingredient,
                                        onDelete: {
                                            if let index = detectedIngredients.firstIndex(of: ingredient) {
                                                detectedIngredients.remove(at: index)
                                            }
                                        }
                                    )
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .offset(y: -20)

            HStack(spacing: 12) {
                Button(action: { showNamingAlert = true }) {
                    Text("Save Meal")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(detectedIngredients.isEmpty ? Color.gray.opacity(0.5) : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                }
                .disabled(detectedIngredients.isEmpty)
                Button(action: { showAddTodayAlert = true }) {
                    HStack{
                        Image(systemName: "plus.circle.fill")
                        Text("Add to Today")
                    }
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(detectedIngredients.isEmpty ? Color.gray.opacity(0.5) : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(15)
                            
                }
                .disabled(detectedIngredients.isEmpty)
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
            .background(Color(.systemBackground))
        }
        .navigationTitle("Live Scan")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .alert("Name your meal", isPresented: $showNamingAlert) {
            TextField("e.g., Morning Shake", text: $mealName)
            Button("Save", action: saveMeal)
            Button("Cancel", role: .cancel) { mealName = "" }
        } message: {
            Text("Save this meal to your favorites")
        }
        .alert("Add to Today", isPresented: $showAddTodayAlert) {
            TextField("Meal name (optional)", text: $mealName)
            Button("Add", action: addToToday)
            Button("Cancel", role: .cancel) { mealName = "" }
        } message: {
            Text("Add this meal to today's nutrition log")
        }
    }

    func saveMeal() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let finalName = mealName.isEmpty ? "Detected Meal" : mealName
        
        let newMeal = Meal(
            userID: uid,
            name: finalName,
            date: Date(),
            isSaved: true,
            ingredients: detectedIngredients
        )
        
        do {
            try db.collection("Users").document(uid).collection("Meals").addDocument(from: newMeal)
            mealName = ""
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            dismiss()
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }
    
    func addToToday() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let finalName = mealName.isEmpty ? "Quick Meal" : mealName
        
        let todayMeal = Meal(
            userID: uid,
            name: finalName,
            date: Date(),
            isSaved: true,
            ingredients: detectedIngredients
        )
        
        do {
            try db.collection("Users").document(uid).collection("Meals").addDocument(from: todayMeal)
            mealName = ""
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            dismiss()
        } catch {
            print("Error adding meal to today: \(error.localizedDescription)")
        }
    }
}
