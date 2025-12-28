//
//  HomeView.swift
//  NutriVision
//
//  Created by Vasco Zambujo on 22/12/2025.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct HomeView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingProfile = false
    @State private var currentUser: User?
    @State private var isLoading = true
    @EnvironmentObject var appState: AppState
    
    @State private var mealHistory: [Meal] = []

    var body: some View {
            NavigationStack {
                ZStack {
                    // Background
                    Color(colorScheme == .light ? .systemGroupedBackground : .black)
                        .ignoresSafeArea()
                    
                    // Use a ScrollView to ensure it fits all screen sizes (Pro vs Mini/SE)
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 20) { // Reduced spacing from 30 to 20
                            
                            // 1. App Logo/Title Section
                            VStack(spacing: 8) {
                                Text("NutriVision")
                                    .font(.system(size: 34, weight: .bold, design: .rounded)) // Slightly smaller
                                
                                Text("Track your nutrition with AI")
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundColor(.gray)
                            }
                            .padding(.top, 10)
                            
                            // 2. Nutrition Insights Card (The Chart)
                            if appState.isLoggedIn {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text("Nutrition Insights")
                                            .font(.system(size: 20, weight: .bold, design: .rounded))
                                        Spacer()
                                        NavigationLink(destination: NutritionStatsView()) {
                                            Text("Full Report")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    .padding(.horizontal, 5)

                                    // The specialized Dashboard Chart
                                    DashboardStatsView()
                                        .frame(height: 260) // Slightly shorter to save space
                                        .cornerRadius(20)
                                }
                                .padding(.horizontal)
                            }
                            
                            // 3. Main Actions
                            VStack(spacing: 12) { // Reduced spacing between buttons
                                // Start Recording
                                NavigationLink(destination: RecordingView()) {
                                    HomeActionButton(
                                        icon: "record.circle.fill",
                                        title: "Start Recording",
                                        subtitle: "Scan your meal",
                                        color: .blue
                                    )
                                }
                                
                                if appState.isLoggedIn {
                                    NavigationLink(destination: HistoryView()) {
                                        HomeActionButton(
                                            icon: "clock.fill",
                                            title: "See History",
                                            subtitle: "View past meals",
                                            color: .green
                                        )
                                    }
                                    
                                    NavigationLink(destination: SavedMealsView()) {
                                        HomeActionButton(
                                            icon: "bookmark.fill",
                                            title: "Saved Meals",
                                            subtitle: "Your favorites",
                                            color: .orange
                                        )
                                    }
                                    
                                    NavigationLink(destination: AISuggestionView(history: mealHistory)) {
                                        HomeActionButton(
                                            icon: "sparkles",
                                            title: "AI Suggestions",
                                            subtitle: "Smart meal ideas based on your diet",
                                            color: .red
                                        )
                                    }
                                } else {
                                    NavigationLink(destination: AuthView()) {
                                        HomeActionButton(
                                            icon: "person.circle.fill",
                                            title: "Login / Register",
                                            subtitle: "Access all features",
                                            color: .purple
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 20) // Extra padding at the bottom for scrolling clearance
                        }
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    if appState.isLoggedIn {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                showingProfile = true
                            } label: {
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
                .sheet(isPresented: $showingProfile) {
                    ProfileView(user: $currentUser)
                }
                .onAppear {
                    if appState.isLoggedIn {
                        fetchUserDataAndMeals()
                    }
                }
            }
        }
    
    func fetchUserDataAndMeals() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        // 1. Fetch User Data (Your existing logic)
        db.collection("Users").document(uid).getDocument { snapshot, _ in
            if let data = snapshot?.data() {
                currentUser = User(
                    id: nil,
                    name: data["name"] as? String ?? "",
                    email: data["email"] as? String ?? "",
                    age: data["age"] as? Int,
                    height: data["height"] as? Int,
                    weight: data["weight"] as? Double
                )
            }
        }
        
        // 2. Fetch Meals for the AI (The logic from your HistoryView)
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        
        db.collection("Users").document(uid).collection("Meals")
            .whereField("date", isGreaterThan: sevenDaysAgo)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                // Store the flat list here to pass to AI Suggestions
                self.mealHistory = documents.compactMap { try? $0.data(as: Meal.self) }
                self.isLoading = false
            }
    }
}

struct HomeActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)
                .frame(width: 44)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(colorScheme == .light ? .primary : .white)
                
                Text(subtitle)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.gray)
        }
        .padding(.vertical, 12) // Slightly tighter padding
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .light ? Color.white : Color(uiColor: .systemGray6))
                .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
        )
    }
}

