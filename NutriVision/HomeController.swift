//
//  HomeController.swift
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

    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(colorScheme == .light ? .systemGroupedBackground : .black)
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // App Logo/Title
                    VStack(spacing: 10) {
                        Image(systemName: "camera.viewfinder")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .blue.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("NutriVision")
                            .font(.system(size: 40, weight: .bold))
                        
                        Text("Track your nutrition with AI")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 40)
                    
                    Spacer()
                    
                    // Main Actions
                    VStack(spacing: 20) {
                        // Start Recording - Always visible
                        NavigationLink(destination: RecordingViewWrapper()) {
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
                        }
                        
                        // Login Button - Only for logged out users
                        if !appState.isLoggedIn {
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
                    
                    Spacer()
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
                                .font(.system(size: 28))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .blue.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    }
                }
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView(user: $currentUser)
            }
            .onAppear {
                if appState.isLoggedIn {
                    fetchCurrentUser()
                }
            }
        }
    }
    
    func fetchCurrentUser() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("Users").document(uid).getDocument { snapshot, error in
            isLoading = false
            
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
    }
}

struct HomeActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 35))
                .foregroundColor(color)
                .frame(width: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(colorScheme == .light ? .primary : .white)
                
                Text(subtitle)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.gray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .light ? Color.white : Color(uiColor: .systemGray6))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// Wrapper for existing UIKit RecordingViewController
struct RecordingViewWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> RecordingViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "RecordingVC") as! RecordingViewController
    }
    
    func updateUIViewController(_ uiViewController: RecordingViewController, context: Context) {}
}

// Placeholder views - implement these based on your needs
struct HistoryView: View {
    var body: some View {
        Text("History View")
            .font(.title)
            .navigationTitle("History")
    }
}

struct SavedMealsView: View {
    var body: some View {
        Text("Saved Meals View")
            .font(.title)
            .navigationTitle("Saved Meals")
    }
}
