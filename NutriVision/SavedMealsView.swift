//
//  SavedMealsView.swift
//  NutriVision
//
//  Created by Vasco Zambujo on 26/12/2025.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct SavedMealsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var meals: [Meal] = []
    @State private var filteredMeals: [Meal] = []
    @State private var searchText = ""
    @State private var isLoading = true
    @State private var expandedMealID: String?
    
    var body: some View {
        ZStack {
            Color(colorScheme == .light ? .systemGroupedBackground : .black)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Search Bar
                SearchBar(text: $searchText)
                    .padding()
                
                if isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                    Spacer()
                } else if filteredMeals.isEmpty {
                    EmptyMealsView(hasSearchText: !searchText.isEmpty)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredMeals, id: \.id) { meal in
                                MealCard(
                                    meal: meal,
                                    isExpanded: expandedMealID == meal.id,
                                    onTap: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            if expandedMealID == meal.id {
                                                expandedMealID = nil
                                            } else {
                                                expandedMealID = meal.id
                                            }
                                        }
                                    },
                                    onDelete: {
                                        deleteMeal(meal)
                                    },
                                    onAddToToday: {
                                        addMealToToday(meal)
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle("Saved Meals")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            fetchSavedMeals()
        }
        .onChange(of: searchText) { newValue in
            filterMeals(searchText: newValue)
        }
    }
    
    func fetchSavedMeals() {
        guard let uid = Auth.auth().currentUser?.uid else {
            isLoading = false
            return
        }
        
        let db = Firestore.firestore()
        
        // Updated to "Users" (Capital U)
        // Sub-collection "meals" (Lowercase m - double check if this should be Meals)
        db.collection("Users").document(uid).collection("Meals")
            .whereField("isSaved", isEqualTo: true)
            .order(by: "date", descending: true)
            .addSnapshotListener { snapshot, error in
                // Stop loading state
                isLoading = false
                
                if let error = error {
                    print("Error fetching meals: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No documents found in the 'meals' collection")
                    self.meals = []
                    self.filteredMeals = []
                    return
                }
                
                // Map Firestore documents to your Meal model
                let decodedMeals = documents.compactMap { document -> Meal? in
                    do {
                        var meal = try document.data(as: Meal.self)
                        // FORCE FIX: If the @DocumentID failed for some reason,
                        // manually assign the document ID here.
                        if meal.id == nil {
                            meal.id = document.documentID
                        }
                        return meal
                    } catch {
                        print("Error decoding meal \(document.documentID): \(error)")
                        return nil
                    }
                }

                // Only keep meals that have a valid ID to satisfy SwiftUI's ForEach
                self.meals = decodedMeals.filter { $0.id != nil }
                
                // Sync the filtered view with the main meals list
                if searchText.isEmpty {
                    filteredMeals = meals
                } else {
                    filterMeals(searchText: searchText)
                }
            }
    }
    
    func filterMeals(searchText: String) {
        if searchText.isEmpty {
            filteredMeals = meals
        } else {
            filteredMeals = meals.filter { meal in
                meal.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    func deleteMeal(_ meal: Meal) {
        guard let uid = Auth.auth().currentUser?.uid,
              let mealID = meal.id else { return }
        
        let db = Firestore.firestore()
        
        db.collection("Users").document(uid).collection("Meals").document(mealID).updateData([
            "isSaved": false
        ]) { error in
            if let error = error {
                print("Error removing saved meal: \(error.localizedDescription)")
            } else {
                // Add this to give the user immediate feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                
                // Close the expanded card after deleting
                withAnimation {
                    expandedMealID = nil
                }
            }
        }
    }
    
    func addMealToToday(_ meal: Meal) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        var dailyMeal = meal
        dailyMeal.id = UUID().uuidString
        dailyMeal.date = Date()
        dailyMeal.isSaved = false
        
        do {
            try db.collection("Users").document(uid).collection("Meals").addDocument(from: dailyMeal)
            print("Meal added to today successfully!")
            
            // Optional: Provide haptic feedback or a toast message
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
        } catch {
            print("Error adding meal to today: \(error.localizedDescription)")
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search meals...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .light ? Color.white : Color(uiColor: .systemGray6))
        )
    }
}

struct MealCard: View {
    let meal: Meal
    let isExpanded: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    let onAddToToday: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var showDeleteAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header (always visible)
            Button(action: onTap) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(meal.name)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(colorScheme == .light ? .primary : .white)
                            .multilineTextAlignment(.leading)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.orange)
                            Text("\(Int(meal.calories)) kcal")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gray)
                }
                .padding()
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded Content
            if isExpanded {
                VStack(spacing: 16) {
                    Divider()
                        .padding(.horizontal)
                    
                    // Ingredients Section
                    if !meal.ingredients.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Ingredients")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .padding(.horizontal)
                            
                            VStack(spacing: 8) {
                                ForEach(meal.ingredients) { ingredient in
                                    IngredientRow(ingredient: ingredient)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        Divider()
                            .padding(.horizontal)
                    }
                    
                    // Macros Grid
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Nutrition")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            MacroItem(icon: "leaf.fill", label: "Protein", value: meal.protein, unit: "g", color: .blue)
                            MacroItem(icon: "bolt.fill", label: "Carbs", value: meal.carbs, unit: "g", color: .green)
                            MacroItem(icon: "drop.fill", label: "Fats", value: meal.fats, unit: "g", color: .red)
                            MacroItem(icon: "flame.fill", label: "Calories", value: meal.calories, unit: "kcal", color: .orange)
                        }
                        .padding(.horizontal)
                    }
                    
                    HStack(spacing: 12) {
                        Button {
                            onAddToToday()
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add to Today")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.blue.opacity(0.1))
                            )
                        }
                        
                        Button {
                            showDeleteAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("Remove")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.red.opacity(0.1))
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .light ? Color.white : Color(uiColor: .systemGray6))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .alert("Remove Saved Meal", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("This meal will be removed from your saved meals.")
        }
    }
}

struct MacroItem: View {
    let icon: String
    let label: String
    let value: Double
    let unit: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)
                
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(String(format: "%.1f", value))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    Text(unit)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }
}

struct EmptyMealsView: View {
    let hasSearchText: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: hasSearchText ? "magnifyingglass" : "bookmark.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(hasSearchText ? "No meals found" : "No Saved Meals")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
            
            Text(hasSearchText ? "Try a different search term" : "Save your favorite meals to access them quickly")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxHeight: .infinity)
    }
}

struct IngredientRow: View {
    let ingredient: Ingredient
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "circle.fill")
                .font(.system(size: 6))
                .foregroundColor(.gray)
            
            Text(ingredient.name)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(colorScheme == .light ? .primary : .white)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(ingredient.formattedAmount)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.gray)
                
                HStack(spacing: 3) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                    Text("\(Int(ingredient.calories)) kcal")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(colorScheme == .light ? Color(uiColor: .systemGray6) : Color(uiColor: .systemGray5))
        )
    }
}
