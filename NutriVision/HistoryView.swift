//
//  HistoryView.swift
//  NutriVision
//
//  Created by Vasco Zambujo on 27/12/2025.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct HistoryView: View {
    @State private var groupedMeals: [Date: [Meal]] = [:]
    @State private var expandedDays: Set<Date> = []
    @State private var isLoading = true
    private let repository: MealRepository
    
    init(repository: MealRepository = FirestoreMealRepository()) {
        self.repository = repository
    }

    // Get the last 7 days including today
    var lastSevenDays: [Date] {
        (0..<7).compactMap { day in
            Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -day, to: Date())!)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if isLoading {
                    ProgressView("Loading History...")
                        .padding(.top, 50)
                } else {
                    ForEach(lastSevenDays, id: \.self) { date in
                        DaySection(
                            date: date,
                            meals: groupedMeals[date] ?? [],
                            isExpanded: expandedDays.contains(date),
                            toggle: {
                                withAnimation(.spring()) {
                                    expandedDays = ExpandedDaysLogic.toggle(date, in: expandedDays)
                                }
                            }
                        )
                    }
                }
            }
            .padding()
        }
        .background(Color(.secondarySystemBackground))
        .navigationTitle("History")
        .onAppear(perform: fetchMeals)
    }

    private func fetchMeals() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        
        db.collection("Users").document(uid).collection("Meals")
            .whereField("date", isGreaterThan: sevenDaysAgo)
            .order(by: "date", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching meals: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                // CRITICAL FIX: Ensure the ID is never nil
                let decodedMeals = documents.compactMap { document -> Meal? in
                    do {
                        var meal = try document.data(as: Meal.self)
                        // If Firestore failed to map the @DocumentID, manually set it
                        if meal.id == nil {
                            meal.id = document.documentID
                        }
                        return meal
                    } catch {
                        print("Decoding error: \(error)")
                        return nil
                    }
                }
                
                // Filter out any that still managed to have a nil ID (to satisfy SwiftUI)
                let validMeals = decodedMeals.filter { $0.id != nil }
                
                self.groupedMeals = HistoryGrouping.groupMealsByDay(validMeals)
                
                if expandedDays.isEmpty {
                    expandedDays = Set(lastSevenDays)
                }
                isLoading = false
            }
    }
    
    func renameMeal(mealID: String, newName: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        repository.renameMeal(userID: uid, mealID: mealID, newName: newName)
    }
}

struct DaySection: View {
    let date: Date
    let meals: [Meal]
    let isExpanded: Bool
    let toggle: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Day Header Button
            Button(action: toggle) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(date.formatted(date: .numeric, time: .omitted))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(date.formatted(.dateTime.weekday(.wide)))
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gray)
                }
                .padding()
                .frame(maxWidth: .infinity) // Ensures button fills width
                .background(Color(.systemBackground))
            }
            
            if isExpanded {
                VStack(spacing: 0) {
                    if meals.isEmpty {
                        HStack {
                            Spacer()
                            Text("No meals recorded")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 20)
                            Spacer()
                        }
                        .background(Color(.systemBackground))
                    } else {
                        ForEach(Array(meals.enumerated()), id: \.element.id) { index, meal in
                            Divider().padding(.horizontal) // Subtle line between meals
                            HistoryMealRow(meal: meal, mealNumber: index + 1)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .background(Color(.systemBackground)) // Base background for the whole card
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct HistoryMealRow: View {
    let meal: Meal
    let mealNumber: Int
    
    @State private var showNamingAlert = false
    @State private var mealName: String = ""
    @State private var isMealExpanded: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Tappable Header
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    isMealExpanded.toggle()
                }
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(meal.name == "Detected Meal" || meal.name.isEmpty ? "Meal #\(mealNumber)" : meal.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("\(meal.ingredients.count) items")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if !isMealExpanded {
                        HStack(spacing: 12) {
                            MacroMiniView(label: "Cals", value: meal.calories, color: .orange)
                            MacroMiniView(label: "Prot", value: meal.protein, color: .green)
                            MacroMiniView(label: "Carbs", value: meal.carbs, color: .purple)
                            MacroMiniView(label: "Fats", value: meal.fats, color: .red)
                        }
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.gray.opacity(0.5))
                        .rotationEffect(.degrees(isMealExpanded ? 90 : 0))
                        .padding(.leading, 4)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .buttonStyle(PlainButtonStyle())
            
            if isMealExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    // 1. Detailed Macro Row
                    HStack(spacing: 0) {
                        FullMacroLabel(label: "Calories", value: meal.calories, unit: "kcal", color: .orange)
                        Spacer()
                        FullMacroLabel(label: "Protein", value: meal.protein, unit: "g", color: .green)
                        Spacer()
                        FullMacroLabel(label: "Carbs", value: meal.carbs, unit: "g", color: .purple)
                        Spacer()
                        FullMacroLabel(label: "Fats", value: meal.fats, unit: "g", color: .red)
                    }
                    .padding(.horizontal)
                    
                    Divider().padding(.horizontal)
                    
                    // 2. Ingredients List
                    VStack(alignment: .leading, spacing: 10) {
                        Text("INGREDIENTS")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        ForEach(meal.ingredients) { ingredient in
                            HStack {
                                Text(ingredient.name).font(.subheadline)
                                Spacer()
                                Text("\(Int(ingredient.amount)) \(ingredient.unit)")
                                    .font(.subheadline).foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // 3. Action Buttons
                    HStack(spacing: 12) {
                        // ONLY SHOW SAVE if not already saved
                        if !(meal.isSaved ?? false) {
                            Button(action: { showNamingAlert = true }) {
                                Text("Save Meal")
                                    .bold()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(15)
                            }
                        }
                        
                        Button(action: { addToToday() }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add to Today")
                            }
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 12)
                }
                .padding(.vertical, 16)
                .background(Color(.secondarySystemBackground).opacity(0.4))
            }
        }
        // Alert for naming the meal when saving
        .alert("Save Meal", isPresented: $showNamingAlert) {
            TextField("Meal Name (e.g. My Favorite Salad)", text: $mealName)
            Button("Save", action: saveToFavorites)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Give this meal a name to find it easily in your Saved Meals.")
        }
    }
        
    func saveToFavorites() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let batch = db.batch()
        
        let finalName = mealName.isEmpty ? (meal.name.isEmpty ? "Saved Meal" : meal.name) : mealName
        
        db.collection("Users").document(uid).collection("Meals")
            .whereField("calories", isEqualTo: meal.calories)
            .whereField("protein", isEqualTo: meal.protein)
            .whereField("carbs", isEqualTo: meal.carbs)
            .whereField("fats", isEqualTo: meal.fats)
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents, !documents.isEmpty else { return }
                
                // 1. Pick the FIRST document to be the "Master Template"
                let masterDoc = documents[0]
                let masterRef = db.collection("Users").document(uid).collection("Meals").document(masterDoc.documentID)
                
                batch.updateData([
                    "name": finalName,
                    "isSaved": true // This is the ONLY one that will show in SavedMealsView
                ], forDocument: masterRef)
                
                // 2. Update ALL OTHER matching documents to the same name
                // but keep isSaved as FALSE
                if documents.count > 1 {
                    for i in 1..<documents.count {
                        let otherRef = db.collection("Users").document(uid).collection("Meals").document(documents[i].documentID)
                        batch.updateData([
                            "name": finalName,
                            "isSaved": false // Hide from SavedMealsView, but keep name in History
                        ], forDocument: otherRef)
                    }
                }
                
                batch.commit { error in
                    if let error = error {
                        print("Error: \(error.localizedDescription)")
                    } else {
                        triggerSuccessFeedback()
                    }
                }
            }
    }
    
    func addToToday() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        // Clone the meal for today's date
        let todayMeal = Meal(
            userID: uid,
            name: meal.name.isEmpty ? "Meal #\(mealNumber)" : meal.name,
            date: Date(), // Set to right now
            isSaved: false, // This is a log entry, not necessarily a favorite template
            ingredients: meal.ingredients
        )
        
        do {
            try db.collection("Users").document(uid).collection("Meals").addDocument(from: todayMeal)
            triggerSuccessFeedback()
        } catch {
            print("Error adding to today: \(error.localizedDescription)")
        }
    }
    
    private func triggerSuccessFeedback() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        withAnimation { isMealExpanded = false } // Collapse after action
    }
}

// Larger macro label used in the expanded view
struct FullMacroLabel: View {
    let label: String
    let value: Double
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(color)
            Text("\(Int(value))\(unit)")
                .font(.system(size: 15, weight: .bold))
        }
    }
}

// Updated MacroMiniView for the collapsed state
struct MacroMiniView: View {
    let label: String
    let value: Double
    let color: Color
    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(label).font(.caption2).bold().foregroundColor(color)
            Text("\(Int(value))\(label == "Cals" ? "" : "g")").font(.caption).bold()
        }
    }
}

struct HistoryGrouping {
    static func groupMealsByDay(_ meals: [Meal]) -> [Date: [Meal]] {
        Dictionary(grouping: meals) {
            Calendar.current.startOfDay(for: $0.date)
        }
    }
}

struct ExpandedDaysLogic {
    static func toggle(_ day: Date, in set: Set<Date>) -> Set<Date> {
        var updated = set
        if updated.contains(day) {
            updated.remove(day)
        } else {
            updated.insert(day)
        }
        return updated
    }
}
