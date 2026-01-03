//
//  RecordingView.swift
//  NutriVision
//
//  Created by Vasco Zambujo on 27/12/2025.
//

import SwiftUI

struct RecordingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = RecordingViewModel()

    var body: some View {
        VStack(spacing: 0) {

            // MARK: - Camera Feed
            ZStack {
                ARCameraView(
                    detectedIngredients: $vm.detectedIngredients,
                    calories: vm.totalCalories,
                    protein: vm.totalProtein,
                    carbs: vm.totalCarbs,
                    fats: vm.totalFats,
                    isScanning: $vm.isScanning
                )
                .ignoresSafeArea()

                calorieOverlay
                scanningOverlay

                if !vm.isScanning {
                    Color.black.opacity(0.25)
                        .ignoresSafeArea()
                        .transition(.opacity)
                }
            }
            .frame(height: UIScreen.main.bounds.height * 0.30)

            // MARK: - Nutrition Details Area
            nutritionDetails

            // MARK: - Action Buttons
            actionButtons
        }
        .onAppear { vm.onAppear() }
        .navigationTitle("Live Scan")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $vm.showNamingAlert) { saveMealAlert }
        .alert(isPresented: $vm.showAddTodayAlert) { addToTodayAlert }
    }
}

// MARK: - UI Helpers
private extension RecordingView {
    
    private var saveMealAlert: Alert {
        Alert(
            title: Text("Name your meal"),
            message: Text("Save this meal to your favorites"),
            primaryButton: .default(Text("Save")) { vm.saveMeal(dismiss: { dismiss() }) },
            secondaryButton: .cancel {
                vm.cancelNaming()
            }
        )
    }

    private var addToTodayAlert: Alert {
        Alert(
            title: Text("Add to Today"),
            message: Text("Add this meal to today's nutrition log"),
            primaryButton: .default(Text("Add")) { vm.addToToday(dismiss: { dismiss() }) },
            secondaryButton: .cancel()
        )
    }

    var calorieOverlay: some View {
        VStack {
            Spacer()
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Kcal daily goal")
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .cornerRadius(10)

                    Text("\(Int(vm.totalCaloriesIncludingToday)) / \(Int(vm.dailyCalorieGoal)) Kcal")
                        .font(.caption2.bold())
                        .foregroundColor(.white.opacity(0.85))

                    Spacer()

                    Text("\(Int(vm.calorieProgress * 100))%")
                        .font(.caption2.bold())
                        .foregroundColor(.orange)
                }

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.orange)
                        .frame(
                            width: CGFloat(vm.calorieProgress) * UIScreen.main.bounds.width * 0.85,
                            height: 8
                        )
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 25)
        }
    }

    var scanningOverlay: some View {
        VStack {
            HStack {
                Spacer()
                Text(vm.isScanning ? "AI ACTIVE" : "PAUSED")
                    .font(.caption2.bold())
                    .padding(6)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                    .padding()
            }
            Spacer()
        }
    }

    var nutritionDetails: some View {
        VStack(spacing: 0) {
            // Horizontal Summary Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 9) {
                    SummaryPill(title: "Calories", value: String(format: "%.0fkcal", vm.totalCalories), icon: "flame.fill", color: .orange)
                    SummaryPill(title: "Protein", value: String(format: "%.1fg", vm.totalProtein), icon: "leaf.fill", color: .green)
                    SummaryPill(title: "Carbs", value: String(format: "%.1fg", vm.totalCarbs), icon: "bolt.fill", color: .purple)
                    SummaryPill(title: "Fats", value: String(format: "%.1fg", vm.totalFats), icon: "drop.fill", color: .red)
                }
                .padding(.horizontal, 16)
                .padding(.top, 25)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text("Detected Ingredients")
                            .font(.title3.bold())

                        Spacer()

                        // Buttons for simulator testing
                        #if targetEnvironment(simulator)
                        HStack(spacing: 8) {
                            Button("🧪 Pizza") { vm.simulateDetection(name: "pizza", grams: 250) }
                            Button("🧪 Apple") { vm.simulateDetection(name: "apple", grams: 150) }
                        }
                        .font(.caption2)
                        .buttonStyle(.bordered)
                        #endif
                    }
                    .padding(.horizontal)

                    if vm.detectedIngredients.isEmpty {
                        VStack(spacing: 10) {
                            ProgressView()
                            Text("Detecting ingredients...")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 50)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(vm.detectedIngredients) { ingredient in
                                DetectedIngredientRow(
                                    ingredient: ingredient,
                                    onDelete: { vm.deleteIngredient(ingredient) }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .offset(y: -20)
    }

    var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                vm.startSaveMeal()
            } label: {
                Text("Save Meal")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(vm.detectedIngredients.isEmpty ? Color.gray.opacity(0.5) : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(15)
            }
            .disabled(vm.detectedIngredients.isEmpty)

            Button {
                vm.startAddToToday()
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add to Today")
                }
                .bold()
                .frame(maxWidth: .infinity)
                .padding()
                .background(vm.detectedIngredients.isEmpty ? Color.gray.opacity(0.5) : Color.green)
                .foregroundColor(.white)
                .cornerRadius(15)
            }
            .disabled(vm.detectedIngredients.isEmpty)
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
        .background(Color(.systemBackground))
    }
}
