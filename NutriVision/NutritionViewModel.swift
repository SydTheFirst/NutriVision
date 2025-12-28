//
//  NutritionViewModel.swift
//  NutriVision
//
//  Created by Vasco Zambujo on 26/12/2025.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class NutritionViewModel: ObservableObject {
    @Published var nutritionData: [NutritionData] = []
    @Published var isLoading = false
    @Published var averageValue: Double = 0
    @Published var totalValue: Double = 0
    @Published var highestValue: Double = 0
    
    private var db = Firestore.firestore()
    
    func fetchData(for span: TimeSpan, macro: MacroType) {
        isLoading = true
        guard let uid = Auth.auth().currentUser?.uid else {
            isLoading = false
            return
        }
        
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -span.days, to: endDate)!
        
        db.collection("Users").document(uid).collection("Meals")
            .whereField("date", isGreaterThanOrEqualTo: startDate)
            .whereField("isSaved", isEqualTo: false)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    self.nutritionData = []
                    self.calculateStats()   
                    self.isLoading = false
                    return
                }
                
                var groupedData: [Date: Double] = [:]
                for document in documents {
                    let data = document.data()
                    guard let timestamp = data["date"] as? Timestamp else { continue }
                    let date = calendar.startOfDay(for: timestamp.dateValue())
                    
                    let value: Double = {
                        switch macro {
                        case .calories: return data["calories"] as? Double ?? 0
                        case .protein: return data["protein"] as? Double ?? 0
                        case .carbs: return data["carbs"] as? Double ?? 0
                        case .fats: return data["fats"] as? Double ?? 0
                        }
                    }()
                    groupedData[date, default: 0] += value
                }
                
                self.nutritionData = groupedData.map { NutritionData(date: $0.key, value: $0.value) }
                    .sorted { $0.date < $1.date }
                
                self.calculateStats()
                self.isLoading = false
            }
    }
    
    private func calculateStats() {
        let values = nutritionData.map { $0.value }
        totalValue = values.reduce(0, +)
        averageValue = values.isEmpty ? 0 : totalValue / Double(values.count)
        highestValue = values.max() ?? 0
    }
    
    private func generateSampleData(span: TimeSpan, macro: MacroType) {
        let calendar = Calendar.current
        let endDate = Date()
        var data: [NutritionData] = []
        let baseValue: Double = {
            switch macro {
            case .calories: return 2000
            case .protein: return 80
            case .carbs: return 250
            case .fats: return 70
            }
        }()
        
        for i in 0..<span.days {
            if let date = calendar.date(byAdding: .day, value: -i, to: endDate) {
                let randomVariation = Double.random(in: 0.7...1.3)
                data.append(NutritionData(date: calendar.startOfDay(for: date), value: baseValue * randomVariation))
            }
        }
        self.nutritionData = data.sorted { $0.date < $1.date }
        calculateStats()
    }
}
