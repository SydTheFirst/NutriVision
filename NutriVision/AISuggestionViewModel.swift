//
//  AISuggestionView.swift
//  NutriVision
//
//  Created by Vasco Zambujo on 27/12/2025.
//

import SwiftUI
import FirebaseVertexAI
import FirebaseAuth
import FirebaseFirestore

@MainActor
class AISuggestionViewModel: ObservableObject {
    @Published var suggestedMeal: Meal?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isRecentlySaved = false
    @Published var dataManager: DataManager

    init(dataManager: DataManager) {
       self.dataManager = dataManager
   }
    
    private let db = Firestore.firestore()
    
    private lazy var model = VertexAI.vertexAI().generativeModel(
        modelName: "gemini-2.0-flash",
        generationConfig: GenerationConfig(
            responseMIMEType: "application/json"
        )
    )
    
    func generateMealSuggestion(
        history: [Meal]
    ) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let user = dataManager.currentUser else { return }

        isLoading = true
        errorMessage = nil
        isRecentlySaved = false

        let historyNames = history.suffix(10).map { $0.name }.joined(separator: ", ")

        // Current hour
        let hour = Calendar.current.component(.hour, from: Date())

        // Meals left in the day
        let mealsLeft: Int
        let mealLabel: String
        switch hour {
        case 5..<12:
            mealsLeft = 4      // breakfast, lunch, dinner
            mealLabel = "breakfast"
        case 12..<18:
            mealsLeft = 2      // lunch, dinner
            mealLabel = "lunch"
        case 18..<21:
            mealsLeft = 2      // dinner
            mealLabel = "dinner"
        default:
            mealsLeft = 1      // snack
            mealLabel = "snack"
        }

        let dailyCalorieGoal = user.dailyCalories ?? 2000
        let todayCalories = dataManager.todayCalories
        let weightGoal = user.weightGoal ?? .maintain
        
        // Suggested kcal for this meal
        let kcalForThisMeal = max(Int((dailyCalorieGoal - todayCalories) / Double(mealsLeft)), 50)
        // minimum 50 kcal so AI doesn’t suggest zero

        // 4️⃣ Prompt for AI
        let prompt = """
        Suggest ONE healthy \(mealLabel) for a user who wants to \(weightGoal.rawValue) weight.
        He has a daily calorie intake goal of \(Int(dailyCalorieGoal)) kcal, and has already consumed \(Int(todayCalories)) kcal today.
        There are approximately \(mealsLeft) meals left today. 
        This meal should roughly contain \(kcalForThisMeal) kcal, appropriate for the remaining meals and the user's goal.
        Consider this recent meal history: \(historyNames).

        Return ONLY a JSON object with this exact structure:
        {
          "name": "Meal Name",
          "calories": 0,
          "protein": 0,
          "carbs": 0,
          "fats": 0,
          "ingredients": [
            {"name": "Ingredient", "amount": 100, "unit": "g", "calories": 50, "protein": 5, "carbs": 2, "fats": 1}
          ]
        }
        """

        do {
            let response = try await model.generateContent(prompt)

            guard let jsonString = response.text, let data = jsonString.data(using: .utf8) else {
                self.errorMessage = "AI returned an empty response."
                self.isLoading = false
                return
            }

            // Decode the meal
            var decodedMeal = try JSONDecoder().decode(Meal.self, from: data)

            // Assign unique ID and metadata
            decodedMeal.userID = uid
            decodedMeal.date = Date()
            decodedMeal.isSaved = false

            self.suggestedMeal = decodedMeal

        } catch {
            self.errorMessage = "AI Error: \(error.localizedDescription)"
        }
        self.isLoading = false
    }
    
    func saveToFavorites() {
        guard let uid = Auth.auth().currentUser?.uid, var meal = suggestedMeal else { return }
        
        meal.isSaved = true
        meal.userID = uid
        // Set a "Template" date in the past so it doesn't show in the 7-day History
        meal.date = Date(timeIntervalSince1970: 0)
        
        // IMPORTANT: Clear the ID so Firestore creates a NEW document instead of
        // potentially overwriting an existing one if ID was set.
        meal.id = nil
        
        do {
            // Use addDocument instead of setData to avoid ID conflicts
            try db.collection("Users").document(uid).collection("Meals").addDocument(from: meal)
            self.isRecentlySaved = true
            triggerSuccessFeedback()
        } catch {
            print("Error saving favorite: \(error)")
        }
    }

    func addToToday() {
        guard let uid = Auth.auth().currentUser?.uid, let meal = suggestedMeal else { return }
        
        var logEntry = meal
        logEntry.id = nil // Let Firestore manage the ID
        logEntry.userID = uid
        logEntry.date = Date() // Today
        logEntry.isSaved = false // This is a log, not a template
        
        do {
            try db.collection("Users").document(uid).collection("Meals").addDocument(from: logEntry)
            triggerSuccessFeedback()
            print("Successfully added to history")
        } catch {
            print("Error adding to history: \(error)")
        }
    }

    private func triggerSuccessFeedback() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

struct AISuggestionView: View {
    @StateObject private var vm: AISuggestionViewModel
    let history: [Meal]
    
    init(history: [Meal], dataManager: DataManager) {
        self.history = history
        _vm = StateObject(wrappedValue: AISuggestionViewModel(dataManager: dataManager))
    }

    var body: some View {
        NavigationView {
            VStack {
                if history.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("No History Yet")
                            .font(.title2)
                            .bold()
                        
                        Text("Log at least one meal in your history to unlock AI suggestions.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        if let meal = vm.suggestedMeal {
                            // CONNECTED TO VIEW MODEL FUNCTIONS
                            SuggestedMealCard(
                                meal: meal,
                                onSave: { vm.saveToFavorites() },
                                onAdd: { vm.addToToday() },
                                isSaved: vm.isRecentlySaved
                            )
                            .transition(.move(edge: .top).combined(with: .opacity))
                        } else if vm.isLoading {
                            VStack(spacing: 20) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                Text("Analyzing your history...")
                                    .foregroundColor(.secondary)
                            }
                            .frame(height: 300)
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 50))
                                    .foregroundColor(.purple)
                                Text("Ready for a suggestion?")
                                    .font(.headline)
                            }
                            .frame(height: 300)
                        }
                    }
                    
                    if let error = vm.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.bottom, 5)
                    }

                    Button(action: {
                        Task { await vm.generateMealSuggestion(history: history) }
                    }) {
                        HStack {
                            Image(systemName: "wand.and.stars")
                            Text(vm.isLoading ? "Generating..." : "Generate Meal")
                        }
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(vm.isLoading ? Color.gray : Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                    }
                    .disabled(vm.isLoading)
                    .padding()
                }
            }
            .navigationTitle("AI Chef")
            .animation(.spring(), value: vm.suggestedMeal)
        }
    }
}

struct SuggestedMealCard: View {
    let meal: Meal
    let onSave: () -> Void
    let onAdd: () -> Void
    var isSaved: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(meal.date.formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(meal.name)
                .font(.title2)
                .bold()
            
            HStack(spacing: 10) {
                MacroPill(label: "Calories", value: meal.calories, color: .orange)
                MacroPill(label: "Proteins", value: meal.protein, color: .red)
                MacroPill(label: "Carbs", value: meal.carbs, color: .blue)
                MacroPill(label: "Fats", value: meal.fats, color: .yellow)
            }

            Divider()
            Text("What's inside:").font(.headline)
            
            ForEach(meal.ingredients, id: \.name) { ingredient in
                HStack {
                    Text(ingredient.name)
                    Spacer()
                    Text("\(Int(ingredient.amount))\(ingredient.unit)")
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // ACTION BUTTONS
            HStack(spacing: 8) { // Reduced spacing
                Button(action: onSave) {
                    Text(isSaved ? "Saved" : "Save Meal")
                        .font(.system(size: 14, weight: .bold)) // Smaller font to fit
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(isSaved ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(isSaved)
                
                Button(action: onAdd) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Today") // Shortened text to ensure single line
                    }
                    .font(.system(size: 14, weight: .bold))
                    .lineLimit(1) // Force single line
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue) // Changed to Green for visual distinction
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
        .padding(.horizontal)
    }
}

struct MacroPill: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        VStack {
            Text("\(Int(value))")
                .bold()
            Text(label)
                .font(.system(size: 10, weight: .bold).uppercaseSmallCaps())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.15))
        .foregroundColor(color)
        .cornerRadius(10)
    }
}
