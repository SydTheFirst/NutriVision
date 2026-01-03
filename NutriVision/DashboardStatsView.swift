//
//  DashboardStatsView.swift
//  NutriVision
//
//  Created by Vasco Zambujo on 26/12/2025.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct DashboardStatsView: View {
    @StateObject private var vm: NutritionViewModel
    @State private var selectedTimeSpan: TimeSpan
    
    init(
        vm: NutritionViewModel = NutritionViewModel(),
        initialTimeSpan: TimeSpan = .daily
    ) {
        _vm = StateObject(wrappedValue: vm)
        _selectedTimeSpan = State(initialValue: initialTimeSpan)
    }
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Nutrition Trend")
                    .font(.headline)
                Spacer()
                Picker("Time", selection: $selectedTimeSpan) {
                    ForEach(TimeSpan.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            
            if vm.isLoading {
                ProgressView().frame(height: 150)
            } else {
                // Use the SAME ChartView component!
                ChartView(data: vm.nutritionData, macroType: .calories, timeSpan: selectedTimeSpan)
                    .frame(height: 150)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(uiColor: .secondarySystemGroupedBackground)))
        .onAppear { vm.fetchData(for: selectedTimeSpan, macro: .calories) }
        .onChange(of: selectedTimeSpan) { newValue in
            vm.fetchData(for: newValue, macro: .calories)
        }
    }
}
